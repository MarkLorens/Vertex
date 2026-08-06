import Foundation

/// A real document rather than just a notification — accepting has to mutate
/// something durable, and it's what stops duplicate requests.
struct FriendRequest: Identifiable, Codable, Hashable {
    let id: RequestID
    var fromUid: UserID
    var toUid: UserID
    var status: Status
    var createdAt: Date

    enum Status: String, Codable, CaseIterable {
        case pending, accepted, ignored
    }
}
