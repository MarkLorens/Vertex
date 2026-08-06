import Foundation

struct User: Identifiable, Codable, Hashable {
    let id: UserID
    var email: String
    /// Lowercased copy of `email`, indexed — friend search is by address because
    /// usernames aren't unique.
    var emailLower: String
    /// Not unique, and changeable.
    var username: String
    /// Index into `DesignTokens.Palette.avatar`. Stored rather than hashed from
    /// the username, so a rename doesn't change someone's colour.
    var avatarColorIndex: Int
    var friendIds: [UserID]
    var createdAt: Date

    init(
        id: UserID,
        email: String,
        username: String,
        avatarColorIndex: Int,
        friendIds: [UserID] = [],
        createdAt: Date = .now
    ) {
        self.id = id
        self.email = email
        self.emailLower = email.lowercased()
        self.username = username
        self.avatarColorIndex = avatarColorIndex
        self.friendIds = friendIds
        self.createdAt = createdAt
    }
}

extension User {
    /// First letters of the first two words — "Mara Ali" reads as MA, "Sam" as S.
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

/// A private note one user keeps against a friend — "Has the big tent", "Drives".
struct FriendNote: Identifiable, Codable, Hashable {
    /// The friend the note is about.
    let id: UserID
    var note: String
}
