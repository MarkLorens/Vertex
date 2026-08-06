import Foundation

/// Reads and writes events. Typed methods rather than a general "patch these
/// fields" call, so nothing Firestore-shaped leaks into the views.
///
/// Every observe returns a stream that keeps firing — two phones on the same
/// event need each other's votes to land without a refresh.
protocol EventRepository: Sendable {
    /// Every event this person is a participant of.
    func observeEvents(for uid: UserID) -> AsyncStream<[Event]>
    /// One event with its participants, slots and availability assembled.
    func observeDetail(_ eventId: EventID) -> AsyncStream<EventDetail>

    func create(_ detail: EventDetail) async throws

    /// Nil clears the vote — tapping the button you already chose un-votes.
    func setVote(eventId: EventID, slotId: SlotID, uid: UserID, vote: Bool?) async throws
    func setVotingFinished(eventId: EventID, uid: UserID, at date: Date?) async throws
    /// Clears everyone's finish flag in one write, for a run-off.
    func resetVotingFinished(eventId: EventID) async throws

    func setDecided(eventId: EventID, slot: Event.DecidedSlot?) async throws
    func setStatus(eventId: EventID, status: Event.Status) async throws
    func setRound(eventId: EventID, round: Int, closesAt: Date) async throws
    func addSlots(eventId: EventID, slots: [Slot]) async throws

    func setCancellation(eventId: EventID, cancellation: Cancellation?) async throws
    func setCancellationVote(eventId: EventID, uid: UserID, cancel: Bool) async throws

    func setAlarm(eventId: EventID, uid: UserID, alarm: Alarm?) async throws
    func setParticipantStatus(eventId: EventID, uid: UserID, status: Participant.Status) async throws
    /// Leaving purges this person's votes and availability and takes them out of
    /// `participantIds`, so every "of n" stays correct without filtering.
    func leave(eventId: EventID, uid: UserID) async throws
}

/// Who you can invite. A stand-in until there's a friends system — right now it
/// lists everyone with an account, which is what makes two-device testing
/// possible without building friend requests first.
protocol UserDirectory: Sendable {
    func observeUsers() -> AsyncStream<[User]>
}
