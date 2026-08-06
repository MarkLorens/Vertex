import Foundation

struct Participant: Identifiable, Codable, Hashable {
    /// The user's uid — one participant document per person per event.
    let id: UserID
    var status: Status

    /// Snapshots of the user record. The only denormalisation in the schema, and
    /// it earns it: an avatar stack renders five people in one read. Goes stale
    /// on a rename, which is the trade.
    var username: String
    var avatarColorIndex: Int

    var invitedAt: Date
    var respondedAt: Date?
    /// Set once availability is in. Gates the move from gathering to voting.
    var availabilitySubmittedAt: Date?
    /// Set by this user's own "Finish voting". Locks their votes — the whole of
    /// "no take-backs" is this one field being non-nil.
    var votingFinishedAt: Date?
    var alarm: Alarm?

    enum Status: String, Codable, CaseIterable {
        case invited
        /// Named `going` rather than `in` — `in` is a Swift keyword.
        case going
        case declined
        case left
    }
}

extension Participant {
    var isActive: Bool { status == .invited || status == .going }
    var hasSubmittedAvailability: Bool { availabilitySubmittedAt != nil }
    var hasFinishedVoting: Bool { votingFinishedAt != nil }

    var initials: String {
        username
            .split(separator: " ")
            .prefix(2)
            .compactMap(\.first)
            .map(String.init)
            .joined()
            .uppercased()
    }

    var avatar: Avatar {
        Avatar(id: id, initials: initials, colorIndex: avatarColorIndex)
    }
}

/// Per user, per event — everyone sets their own.
struct Alarm: Codable, Hashable {
    var enabled: Bool
    var offset: Offset
    var sound: String

    enum Offset: String, Codable, CaseIterable {
        case atTime, thirtyMinutes, twoHours, nightBefore

        var label: String {
            switch self {
            case .atTime: "At the time"
            case .thirtyMinutes: "30 min before"
            case .twoHours: "2 hours before"
            case .nightBefore: "The night before"
            }
        }
    }
}
