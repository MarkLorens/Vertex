import Foundation

/// In-memory repository so previews and the design harness keep working without
/// Firebase. Mutations apply straight away and re-emit, matching how Firestore's
/// local cache makes a write visible before the server confirms it.
final class MockEventRepository: EventRepository, UserDirectory, @unchecked Sendable {

    private var details: [EventID: EventDetail]
    private var users: [User]
    private let lock = NSLock()
    private var eventListeners: [UUID: (UserID, AsyncStream<[Event]>.Continuation)] = [:]
    private var detailListeners: [UUID: (EventID, AsyncStream<EventDetail>.Continuation)] = [:]

    init(seed: [EventDetail] = MockData.yourEvents, users: [User] = MockData.everyone) {
        details = Dictionary(uniqueKeysWithValues: seed.map { ($0.event.id, $0) })
        self.users = users
    }

    // MARK: - Reading

    func observeEvents(for uid: UserID) -> AsyncStream<[Event]> {
        AsyncStream { continuation in
            let key = UUID()
            lock.withLock { eventListeners[key] = (uid, continuation) }
            continuation.yield(snapshotEvents(for: uid))
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.lock.withLock {
                        self?.eventListeners.removeValue(forKey: key)
                    }
                }
            }
        }
    }

    func observeDetail(_ eventId: EventID) -> AsyncStream<EventDetail> {
        AsyncStream { continuation in
            let key = UUID()
            lock.withLock { detailListeners[key] = (eventId, continuation) }
            if let detail = lock.withLock({ details[eventId] }) { continuation.yield(detail) }
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.lock.withLock {
                        self?.detailListeners.removeValue(forKey: key)
                    }
                }
            }
        }
    }

    func observeUsers() -> AsyncStream<[User]> {
        AsyncStream { continuation in
            continuation.yield(lock.withLock { users })
        }
    }

    // MARK: - Writing

    func create(_ detail: EventDetail) async throws {
        mutate(detail.event.id) { $0 = detail }
    }

    func setVote(eventId: EventID, slotId: SlotID, uid: UserID, vote: Bool?) async throws {
        mutate(eventId) { detail in
            guard let index = detail.slots.firstIndex(where: { $0.id == slotId }) else { return }
            detail.slots[index].votes[uid] = vote
        }
    }

    func setVotingFinished(eventId: EventID, uid: UserID, at date: Date?) async throws {
        mutate(eventId) { detail in
            guard let index = detail.participants.firstIndex(where: { $0.id == uid }) else { return }
            detail.participants[index].votingFinishedAt = date
        }
    }

    func resetVotingFinished(eventId: EventID) async throws {
        mutate(eventId) { detail in
            for index in detail.participants.indices { detail.participants[index].votingFinishedAt = nil }
        }
    }

    func setDecided(eventId: EventID, slot: Event.DecidedSlot?) async throws {
        mutate(eventId) { $0.event.decided = slot }
    }

    func setStatus(eventId: EventID, status: Event.Status) async throws {
        mutate(eventId) { $0.event.status = status }
    }

    func setRound(eventId: EventID, round: Int, closesAt: Date) async throws {
        mutate(eventId) {
            $0.event.round = round
            $0.event.votingClosesAt = closesAt
        }
    }

    func addSlots(eventId: EventID, slots: [Slot]) async throws {
        mutate(eventId) { $0.slots.append(contentsOf: slots) }
    }

    func setCancellation(eventId: EventID, cancellation: Cancellation?) async throws {
        mutate(eventId) { $0.event.cancellation = cancellation }
    }

    func setCancellationVote(eventId: EventID, uid: UserID, cancel: Bool) async throws {
        mutate(eventId) { $0.event.cancellation?.votes[uid] = cancel }
    }

    func setAlarm(eventId: EventID, uid: UserID, alarm: Alarm?) async throws {
        mutate(eventId) { detail in
            guard let index = detail.participants.firstIndex(where: { $0.id == uid }) else { return }
            detail.participants[index].alarm = alarm
        }
    }

    func setParticipantStatus(eventId: EventID, uid: UserID, status: Participant.Status) async throws {
        mutate(eventId) { detail in
            guard let index = detail.participants.firstIndex(where: { $0.id == uid }) else { return }
            detail.participants[index].status = status
            detail.participants[index].respondedAt = .now
        }
    }

    func leave(eventId: EventID, uid: UserID) async throws {
        mutate(eventId) { detail in
            detail.event.participantIds.removeAll { $0 == uid }
            if let index = detail.participants.firstIndex(where: { $0.id == uid }) {
                detail.participants[index].status = .left
            }
            detail.availability.removeAll { $0.id == uid }
            for index in detail.slots.indices { detail.slots[index].votes[uid] = nil }
            detail.event.cancellation?.votes[uid] = nil
        }
    }

    // MARK: - Plumbing

    private func snapshotEvents(for uid: UserID) -> [Event] {
        lock.withLock {
            details.values.map(\.event).filter { $0.participantIds.contains(uid) }
        }
    }

    private func mutate(_ eventId: EventID, _ change: (inout EventDetail) -> Void) {
        var updated: EventDetail?
        lock.withLock {
            var detail = details[eventId] ?? EventDetail(event: blank(eventId))
            change(&detail)
            details[eventId] = detail
            updated = detail
        }
        guard let updated else { return }

        let (detailTargets, eventTargets) = lock.withLock {
            (detailListeners.values.filter { $0.0 == eventId }.map(\.1),
             eventListeners.values.map { ($0.0, $0.1) })
        }
        for continuation in detailTargets { continuation.yield(updated) }
        for (uid, continuation) in eventTargets { continuation.yield(snapshotEvents(for: uid)) }
    }

    private func blank(_ id: EventID) -> Event {
        Event(id: id, name: "", place: "", duration: .evening, organiserId: "",
              createdAt: .now, status: .voting, availabilityClosesAt: .now,
              votingClosesAt: .now, round: 1, participantIds: [], decided: nil, cancellation: nil)
    }
}

private extension NSLock {
    func withLock<T>(_ work: () -> T) -> T {
        lock()
        defer { unlock() }
        return work()
    }
}
