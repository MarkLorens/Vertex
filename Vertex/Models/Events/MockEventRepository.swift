import Foundation

/// In-memory repository so previews and the design harness keep working without
/// Firebase. Mutations apply straight away and re-emit, matching how Firestore's
/// local cache makes a write visible before the server confirms it.
final class MockEventRepository: EventRepository, UserDirectory, @unchecked Sendable {

    private var details: [EventID: EventDetail]
    fileprivate var users: [User]
    fileprivate let lock = NSLock()
    private var eventListeners: [UUID: (UserID, AsyncStream<[Event]>.Continuation)] = [:]
    private var detailListeners: [UUID: (EventID, AsyncStream<EventDetail>.Continuation)] = [:]
    fileprivate var requests: [FriendRequest] = []
    fileprivate var accepted: [FriendRequest] = []
    fileprivate var acceptedListeners: [UUID: (UserID, AsyncStream<[FriendRequest]>.Continuation)] = [:]
    fileprivate var friendListeners: [UUID: (UserID, AsyncStream<[User]>.Continuation)] = [:]
    fileprivate var requestListeners: [UUID: (UserID, Bool, AsyncStream<[FriendRequest]>.Continuation)] = [:]
    fileprivate var userListeners: [UUID: AsyncStream<User>.Continuation] = [:]

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
        Event(id: id, name: "", place: "", organiserId: "",
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

// MARK: - Friends

extension MockEventRepository {

    func observeUser(_ uid: UserID) -> AsyncStream<User> {
        AsyncStream { continuation in
            let key = UUID()
            lock.withLock { userListeners[key] = continuation }
            if let user = lock.withLock({ users.first { $0.id == uid } }) { continuation.yield(user) }
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.lock.withLock { _ = self?.userListeners.removeValue(forKey: key) }
                }
            }
        }
    }

    func observeFriends(of uid: UserID) -> AsyncStream<[User]> {
        AsyncStream { continuation in
            let key = UUID()
            lock.withLock { friendListeners[key] = (uid, continuation) }
            continuation.yield(snapshotFriends(of: uid))
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.lock.withLock { _ = self?.friendListeners.removeValue(forKey: key) }
                }
            }
        }
    }

    func observeIncomingRequests(for uid: UserID) -> AsyncStream<[FriendRequest]> {
        AsyncStream { continuation in
            let key = UUID()
            lock.withLock { requestListeners[key] = (uid, false, continuation) }
            continuation.yield(snapshotRequests(uid, outgoing: false))
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor [weak self ] in
                    self?.lock.withLock { _ = self?.requestListeners.removeValue(forKey: key) }
                }
            }
        }
    }

    func observeOutgoingRequests(from uid: UserID) -> AsyncStream<[FriendRequest]> {
        AsyncStream { continuation in
            let key = UUID()
            lock.withLock { requestListeners[key] = (uid, true, continuation) }
            continuation.yield(snapshotRequests(uid, outgoing: true))
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.lock.withLock { _ = self?.requestListeners.removeValue(forKey: key) }
                }
            }
        }
    }

    func observeAcceptedRequests(from uid: UserID) -> AsyncStream<[FriendRequest]> {
        AsyncStream { continuation in
            let key = UUID()
            lock.withLock { acceptedListeners[key] = (uid, continuation) }
            continuation.yield(snapshotAccepted(uid))
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.lock.withLock { _ = self?.acceptedListeners.removeValue(forKey: key) }
                }
            }
        }
    }

    func participation(eventId: EventID, uid: UserID) async throws -> Participant? {
        lock.withLock { details[eventId]?.participants.first { $0.id == uid } }
    }

    fileprivate func snapshotAccepted(_ uid: UserID) -> [FriendRequest] {
        lock.withLock { accepted.filter { $0.fromUid == uid } }
    }

    func findUser(email: String) async throws -> User? {
        try await Task.sleep(for: .milliseconds(350))
        let address = email.trimmingCharacters(in: .whitespaces).lowercased()
        return lock.withLock { users.first { $0.emailLower == address } }
    }

    /// Same guarantee as Firestore: one document per direction, whatever the
    /// tap count.
    func sendFriendRequest(from: UserID, to: UserID) async throws {
        guard from != to else { return }
        var reciprocal: FriendRequest?
        lock.withLock {
            let alreadyFriends = users.first { $0.id == from }?.friendIds.contains(to) ?? false
            guard !alreadyFriends else { return }
            reciprocal = requests.first { $0.fromUid == to && $0.toUid == from }
            guard reciprocal == nil else { return }
            let id = "\(from)_\(to)"
            guard !requests.contains(where: { $0.id == id }) else { return }
            requests.append(FriendRequest(id: id, fromUid: from, toUid: to,
                                          status: .pending, createdAt: .now, respondedAt: nil))
        }
        if let reciprocal {
            try await acceptFriendRequest(reciprocal)
        } else {
            notifyFriends()
        }
    }

    func acceptFriendRequest(_ request: FriendRequest) async throws {
        lock.withLock {
            requests.removeAll { $0.id == request.id }
            var settled = request
            settled.status = .accepted
            settled.respondedAt = .now
            accepted.append(settled)
            link(request.fromUid, request.toUid)
        }
        notifyFriends()
    }

    func ignoreFriendRequest(_ request: FriendRequest) async throws {
        lock.withLock { requests.removeAll { $0.id == request.id } }
        notifyFriends()
    }

    func removeFriend(uid: UserID, friend: UserID) async throws {
        lock.withLock {
            unlink(uid, friend)
        }
        notifyFriends()
    }

    // MARK: Plumbing

    private func link(_ a: UserID, _ b: UserID) {
        for (index, user) in users.enumerated() {
            if user.id == a, !user.friendIds.contains(b) { users[index].friendIds.append(b) }
            if user.id == b, !user.friendIds.contains(a) { users[index].friendIds.append(a) }
        }
    }

    private func unlink(_ a: UserID, _ b: UserID) {
        for (index, user) in users.enumerated() {
            if user.id == a { users[index].friendIds.removeAll { $0 == b } }
            if user.id == b { users[index].friendIds.removeAll { $0 == a } }
        }
    }

    private func snapshotFriends(of uid: UserID) -> [User] {
        lock.withLock {
            guard let me = users.first(where: { $0.id == uid }) else { return [] }
            return users.filter { me.friendIds.contains($0.id) }.sorted { $0.username < $1.username }
        }
    }

    private func snapshotRequests(_ uid: UserID, outgoing: Bool) -> [FriendRequest] {
        lock.withLock {
            requests.filter { outgoing ? $0.fromUid == uid : $0.toUid == uid }
        }
    }

    private func notifyFriends() {
        let (friendTargets, requestTargets, userTargets) = lock.withLock {
            (friendListeners.values.map { ($0.0, $0.1) },
             requestListeners.values.map { ($0.0, $0.1, $0.2) },
             userListeners.values.map { $0 })
        }
        for (uid, continuation) in friendTargets { continuation.yield(snapshotFriends(of: uid)) }
        for (uid, outgoing, continuation) in requestTargets {
            continuation.yield(snapshotRequests(uid, outgoing: outgoing))
        }
        let acceptedTargets = lock.withLock { acceptedListeners.values.map { ($0.0, $0.1) } }
        for (uid, continuation) in acceptedTargets { continuation.yield(snapshotAccepted(uid)) }
        let everyone = lock.withLock { users }
        for continuation in userTargets {
            if let first = everyone.first { continuation.yield(first) }
        }
    }
}
