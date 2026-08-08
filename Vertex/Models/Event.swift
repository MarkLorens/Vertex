import Foundation

struct Event: Identifiable, Codable, Hashable {
    let id: EventID
    var name: String
    var place: String
    /// Whoever created it. Carries no special powers — finishing voting is
    /// per-user and anyone can propose cancelling.
    var organiserId: UserID
    var createdAt: Date

    var status: Status
    /// Both deadlines are non-optional on purpose: every phase gate is "everyone
    /// must finish", nobody has an override, so without them one unresponsive
    /// person freezes the event permanently.
    var availabilityClosesAt: Date
    var votingClosesAt: Date
    /// 1, or 2 once a tie forces a run-off.
    var round: Int

    /// The only denominator in the app. Declining and leaving both remove a uid
    /// from here, which is what makes every "of n" correct without filtering.
    var participantIds: [UserID]
    var decided: DecidedSlot?
    var cancellation: Cancellation?

    enum Status: String, Codable, CaseIterable {
        case gathering, voting, decided, cancelled
    }

    struct DecidedSlot: Codable, Hashable {
        var slotId: SlotID
        var start: Date
        var end: Date
    }
}

extension Event {
    var participantCount: Int { participantIds.count }

    /// More than half, both to cancel and to keep — derived rather than stored,
    /// because it has to move when someone leaves.
    var cancelThreshold: Int { participantCount / 2 + 1 }

    var isSettled: Bool { status == .decided }
    var isDeciding: Bool { status == .gathering || status == .voting }

    func includes(_ uid: UserID) -> Bool { participantIds.contains(uid) }
}

struct Cancellation: Codable, Hashable {
    var proposedBy: UserID
    /// Required. Asking the group to bin a plan without saying why is a demand,
    /// not a proposal.
    var reason: String
    var createdAt: Date
    /// Without this a cancel vote nobody finishes leaves the event stuck in the
    /// cancelling state while the plan is still happening.
    var expiresAt: Date
    /// true = cancel it, false = keep it on. Absent = hasn't voted.
    var votes: [UserID: Bool]
}

extension Cancellation {
    var cancelVotes: Int { votes.values.filter { $0 }.count }
    var keepVotes: Int { votes.count - cancelVotes }

    func outcome(threshold: Int) -> Outcome {
        if cancelVotes >= threshold { return .cancel }
        if keepVotes >= threshold { return .keep }
        return .open
    }

    enum Outcome { case open, cancel, keep }
}
