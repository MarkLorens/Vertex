import Foundation

/// A proposed time. A range, not an instant — the design shows "Fri 12 — Sun 14 Sep".
struct Slot: Identifiable, Codable, Hashable {
    let id: SlotID
    var start: Date
    var end: Date
    var proposedBy: UserID
    /// Which voting round this slot belongs to. A run-off carries only the tied
    /// slots forward at round 2.
    var round: Int
    /// true = yes, false = no. A missing key is "hasn't voted" — never stored,
    /// so nobody can be recorded as both waiting and voted.
    var votes: [UserID: Bool]

    /// A map on the slot rather than a subcollection: groups are 5–9 people, so
    /// one read gets the whole tally and write contention isn't a concern.
    init(
        id: SlotID,
        start: Date,
        end: Date,
        proposedBy: UserID,
        round: Int = 1,
        votes: [UserID: Bool] = [:]
    ) {
        self.id = id
        self.start = start
        self.end = end
        self.proposedBy = proposedBy
        self.round = round
        self.votes = votes
    }
}

extension Slot {
    var yesCount: Int { votes.values.filter { $0 }.count }
    var noCount: Int { votes.count - yesCount }

    func vote(by uid: UserID) -> Bool? { votes[uid] }
    func hasVoted(_ uid: UserID) -> Bool { votes[uid] != nil }

    func tally(participantCount: Int) -> VoteTally {
        VoteTally(
            yes: yesCount,
            no: noCount,
            waiting: max(0, participantCount - votes.count)
        )
    }
}

struct VoteTally: Hashable {
    let yes: Int
    let no: Int
    let waiting: Int

    var cast: Int { yes + no }
    var total: Int { cast + waiting }
    /// The ranking rule is still open — see Vertex-DataModel.md. This is the
    /// margin the `yes − no` reading would sort on.
    var net: Int { yes - no }
}

/// The days one person marked as workable in step 3.
struct Availability: Identifiable, Codable, Hashable {
    /// The user's uid.
    let id: UserID
    var days: [Date]
}
