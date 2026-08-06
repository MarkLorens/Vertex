import Foundation

/// An event with its subcollections assembled — what a repository hands a screen,
/// and where anything spanning more than one collection is derived.
struct EventDetail: Identifiable, Hashable {
    var event: Event
    var participants: [Participant]
    var slots: [Slot]
    var availability: [Availability]

    var id: EventID { event.id }

    init(
        event: Event,
        participants: [Participant] = [],
        slots: [Slot] = [],
        availability: [Availability] = []
    ) {
        self.event = event
        self.participants = participants
        self.slots = slots
        self.availability = availability
    }
}

// MARK: - People

extension EventDetail {
    /// Everyone still in — declined and departed people are already out of
    /// `participantIds`, so this and the denominator agree by construction.
    var activeParticipants: [Participant] {
        participants.filter { event.includes($0.id) }
    }

    var going: [Participant] { activeParticipants.filter { $0.status == .going } }

    /// Invited but not yet answered — "Nina's thinking" on the Upcoming card.
    var undecided: [Participant] { activeParticipants.filter { $0.status == .invited } }

    var avatars: [Avatar] { activeParticipants.map(\.avatar) }

    func participant(_ uid: UserID) -> Participant? {
        participants.first { $0.id == uid }
    }
}

// MARK: - Phase gates

extension EventDetail {
    var submittedAvailabilityCount: Int {
        activeParticipants.filter(\.hasSubmittedAvailability).count
    }

    /// "4 of 7 voted" — finishing is the per-user commit, so that's what counts.
    var finishedVotingCount: Int {
        activeParticipants.filter(\.hasFinishedVoting).count
    }

    var everyoneSubmittedAvailability: Bool {
        !activeParticipants.isEmpty && submittedAvailabilityCount == event.participantCount
    }

    var everyoneFinishedVoting: Bool {
        !activeParticipants.isEmpty && finishedVotingCount == event.participantCount
    }

    /// Either gate opens on unanimity or on its deadline. Re-check this after
    /// anyone leaves — a departure changes the denominator and can complete a
    /// gate that was still waiting on them.
    func canOpenVoting(now: Date = .now) -> Bool {
        event.status == .gathering
            && (everyoneSubmittedAvailability || now > event.availabilityClosesAt)
    }

    func canDecide(now: Date = .now) -> Bool {
        event.status == .voting
            && (everyoneFinishedVoting || now > event.votingClosesAt)
    }
}

// MARK: - Votes

extension EventDetail {
    var currentRoundSlots: [Slot] {
        slots.filter { $0.round == event.round }.sorted { $0.start < $1.start }
    }

    func tally(for slot: Slot) -> VoteTally {
        slot.tally(participantCount: event.participantCount)
    }

    /// The winning rule is still an open product decision, so it's a parameter
    /// rather than a hard-coded sort. See Vertex-DataModel.md.
    enum Ranking {
        /// Maximises heads in the room — right if a "no" means "I can't make it".
        case mostYes
        /// Penalises objections — right if a "no" means "I'd rather not".
        case netYes
    }

    func rankedSlots(by ranking: Ranking = .mostYes) -> [Slot] {
        currentRoundSlots.sorted { a, b in
            let left = tally(for: a), right = tally(for: b)
            switch ranking {
            case .mostYes:
                return (left.yes, -left.no) > (right.yes, -right.no)
            case .netYes:
                return (left.net, left.yes) > (right.net, right.yes)
            }
        }
    }

    func leadingSlot(by ranking: Ranking = .mostYes) -> Slot? {
        rankedSlots(by: ranking).first
    }

    /// True when more than one slot ties at the top — a run-off, not a winner.
    func isDraw(by ranking: Ranking = .mostYes) -> Bool {
        let ranked = rankedSlots(by: ranking)
        guard ranked.count > 1 else { return false }
        let first = tally(for: ranked[0]), second = tally(for: ranked[1])
        switch ranking {
        case .mostYes: return first.yes == second.yes && first.no == second.no
        case .netYes: return first.net == second.net && first.yes == second.yes
        }
    }

    /// Drives the "Needs you" pill.
    func needsVote(from uid: UserID) -> Bool {
        guard event.status == .voting,
              let me = participant(uid), !me.hasFinishedVoting
        else { return false }
        return currentRoundSlots.contains { !$0.hasVoted(uid) }
    }
}

// MARK: - Cancelling

extension EventDetail {
    var cancelOutcome: Cancellation.Outcome? {
        event.cancellation?.outcome(threshold: event.cancelThreshold)
    }

    var isCancelVoteOpen: Bool { cancelOutcome == .open }
}
