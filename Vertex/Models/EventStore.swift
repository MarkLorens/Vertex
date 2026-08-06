import Foundation
import Observation

/// Holds one event and applies the flow's rules to it.
///
/// Every mutation writes to the repository rather than to `detail` directly —
/// Firestore applies a write to its local cache immediately and fires the
/// listener before the server confirms, so the UI still moves at once and two
/// devices converge on the same state.
@Observable
final class EventStore {
    private(set) var detail: EventDetail
    let currentUserId: UserID

    private let repository: EventRepository

    init(detail: EventDetail, currentUserId: UserID, repository: EventRepository = MockEventRepository()) {
        self.detail = detail
        self.currentUserId = currentUserId
        self.repository = repository
    }

    /// Pushed in by whoever owns the subscription — one listener, one owner.
    func receive(_ fresh: EventDetail) {
        detail = fresh
        // Whoever's device notices first moves the event on; the writes are
        // idempotent, so two devices racing lands on the same result.
        resolveIfReady()
        resolveCancellation()
    }

    var event: Event { detail.event }
    var me: Participant? { detail.participant(currentUserId) }
    var hasFinishedVoting: Bool { me?.hasFinishedVoting ?? false }

    /// Which of 3d–3h to show.
    var stage: Stage {
        if detail.isCancelVoteOpen { return .cancelVote }
        switch event.status {
        case .decided, .cancelled: return .lockedIn
        case .gathering, .voting:
            if event.round > 1 { return .runoff }
            if detail.canDecide() { return detail.isDraw() ? .draw : .lockedIn }
            return .voting
        }
    }

    enum Stage { case voting, draw, runoff, lockedIn, cancelVote }

    // MARK: - Voting

    func myVote(on slot: Slot) -> Bool? { slot.vote(by: currentUserId) }

    /// Votes flip freely until this user finishes — that's where "no take-backs"
    /// starts, and it's per person rather than for the whole group.
    func vote(_ yes: Bool, on slot: Slot) {
        guard !hasFinishedVoting, event.status == .voting else { return }
        let next: Bool? = slot.vote(by: currentUserId) == yes ? nil : yes
        write { try await $0.setVote(eventId: self.event.id, slotId: slot.id, uid: self.currentUserId, vote: next) }
    }

    var hasVotedOnEverything: Bool {
        detail.currentRoundSlots.allSatisfy { $0.hasVoted(currentUserId) }
    }

    func finishVoting() {
        write { try await $0.setVotingFinished(eventId: self.event.id, uid: self.currentUserId, at: .now) }
    }

    /// Most yes wins, ties broken by fewest no. Kept deliberately simple — the
    /// ranking rule is still an open product decision.
    func resolveIfReady() {
        guard event.status == .voting, detail.canDecide(), !detail.isDraw() else { return }
        guard let winner = detail.leadingSlot() else { return }
        let decided = Event.DecidedSlot(slotId: winner.id, start: winner.start, end: winner.end)
        write {
            try await $0.setDecided(eventId: self.event.id, slot: decided)
            try await $0.setStatus(eventId: self.event.id, status: .decided)
        }
    }

    /// A tie sends the top two through to a second round; everyone's finish flag
    /// resets so they can vote again.
    func startRunoff() {
        let contenders = Array(detail.rankedSlots().prefix(2))
        let nextRound = event.round + 1
        let slots = contenders.map {
            Slot(id: "\($0.id)_r\(nextRound)", start: $0.start, end: $0.end,
                 proposedBy: $0.proposedBy, round: nextRound)
        }
        write {
            try await $0.addSlots(eventId: self.event.id, slots: slots)
            try await $0.resetVotingFinished(eventId: self.event.id)
            try await $0.setRound(eventId: self.event.id, round: nextRound,
                                  closesAt: .now.addingTimeInterval(4 * 3600))
            try await $0.setStatus(eventId: self.event.id, status: .voting)
        }
    }

    func pickManually(_ slot: Slot) {
        let decided = Event.DecidedSlot(slotId: slot.id, start: slot.start, end: slot.end)
        write {
            try await $0.setDecided(eventId: self.event.id, slot: decided)
            try await $0.setStatus(eventId: self.event.id, status: .decided)
        }
    }

    /// "Settled by 6 votes to 1" — the winning slot's own split.
    var settledMargin: (yes: Int, no: Int)? {
        guard let decided = event.decided,
              let slot = detail.slots.first(where: { $0.id == decided.slotId })
        else { return nil }
        return (slot.yesCount, slot.noCount)
    }

    // MARK: - Alarm

    var alarm: Alarm {
        me?.alarm ?? Alarm(enabled: false, offset: .twoHours, sound: "Campfire")
    }

    func updateAlarm(_ transform: (inout Alarm) -> Void) {
        var current = alarm
        transform(&current)
        let updated = current
        write { try await $0.setAlarm(eventId: self.event.id, uid: self.currentUserId, alarm: updated) }
    }

    // MARK: - Attending

    func respond(going: Bool) {
        write {
            try await $0.setParticipantStatus(eventId: self.event.id, uid: self.currentUserId,
                                              status: going ? .going : .declined)
        }
    }

    func leave() {
        write { try await $0.leave(eventId: self.event.id, uid: self.currentUserId) }
    }

    // MARK: - Cancelling

    func proposeCancellation(reason: String) {
        let cancellation = Cancellation(
            proposedBy: currentUserId,
            reason: reason,
            createdAt: .now,
            expiresAt: .now.addingTimeInterval(48 * 3600),
            votes: [currentUserId: true]
        )
        write { try await $0.setCancellation(eventId: self.event.id, cancellation: cancellation) }
    }

    func voteOnCancellation(cancel: Bool) {
        guard event.cancellation != nil else { return }
        write { try await $0.setCancellationVote(eventId: self.event.id, uid: self.currentUserId, cancel: cancel) }
    }

    /// Re-checked on every change, and it must also be re-checked whenever
    /// someone leaves — the threshold moves with the participant count.
    func resolveCancellation() {
        switch detail.cancelOutcome {
        case .cancel:
            write {
                try await $0.setStatus(eventId: self.event.id, status: .cancelled)
                try await $0.setCancellation(eventId: self.event.id, cancellation: nil)
            }
        case .keep:
            write { try await $0.setCancellation(eventId: self.event.id, cancellation: nil) }
        case .open, .none:
            break
        }
    }

    func participants(votingToCancel cancel: Bool) -> [Participant] {
        guard let votes = event.cancellation?.votes else { return [] }
        return detail.activeParticipants.filter { votes[$0.id] == cancel }
    }

    /// Still keen shows everyone who hasn't voted to cancel, with non-voters
    /// drawn as outlines — they haven't actually said anything yet.
    func participantsNotVotedOnCancellation() -> [Participant] {
        guard let votes = event.cancellation?.votes else { return detail.activeParticipants }
        return detail.activeParticipants.filter { votes[$0.id] == nil }
    }

    // MARK: - Plumbing

    /// Views call these from buttons, so the work is fired and forgotten. The
    /// listener is what brings the result back.
    private func write(_ work: @escaping (EventRepository) async throws -> Void) {
        Task { [repository] in
            do { try await work(repository) } catch { print("EventStore write failed: \(error)") }
        }
    }
}
