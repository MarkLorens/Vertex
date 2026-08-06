import Foundation

/// Named `AppNotification` because `Notification` is Foundation's.
///
/// Carries references, not a rendered sentence — a stored string can't be
/// localised and goes stale when someone renames themselves.
struct AppNotification: Identifiable, Codable, Hashable {
    let id: NotificationID
    var type: Kind
    /// Whoever caused it — the requester, the organiser.
    var actorUid: UserID
    var eventId: EventID?
    var requestId: RequestID?
    var createdAt: Date
    /// Nil while it belongs under "New"; set moves it to "Earlier".
    var readAt: Date?

    enum Kind: String, Codable, CaseIterable {
        case friendRequest
        case friendAccepted
        case eventInvite
        case eventDecided
        case cancelVoteOpened
    }

    var isUnread: Bool { readAt == nil }
}
