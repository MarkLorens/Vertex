import Foundation

/// In-memory stand-in so previews and the design harness can drive the whole
/// flow without a network or a Firebase project.
final class MockAuthService: AuthProviding, @unchecked Sendable {

    private struct Account {
        var user: User
        var password: String
    }

    private var accounts: [String: Account]
    private(set) var currentUserId: UserID?
    /// Set to watch the failure states without needing a bad password.
    var forcedError: AuthError?

    init(seed: [User] = MockData.everyone, password: String = "password", signedIn: UserID? = nil) {
        accounts = Dictionary(
            uniqueKeysWithValues: seed.map { ($0.emailLower, Account(user: $0, password: password)) }
        )
        currentUserId = signedIn
    }

    func signIn(email: String, password: String) async throws -> UserID {
        try await pause()
        if let forcedError { throw forcedError }
        guard let account = accounts[email.lowercased().trimmingCharacters(in: .whitespaces)] else {
            throw AuthError.userNotFound
        }
        guard account.password == password else { throw AuthError.wrongPassword }
        currentUserId = account.user.id
        return account.user.id
    }

    func register(email: String, password: String, username: String) async throws -> UserID {
        try await pause()
        if let forcedError { throw forcedError }
        let address = email.trimmingCharacters(in: .whitespaces)
        guard !accounts.keys.contains(address.lowercased()) else { throw AuthError.emailInUse }
        let user = User(
            id: "u_\(UUID().uuidString.prefix(6))",
            email: address,
            username: username.trimmingCharacters(in: .whitespaces),
            avatarColorIndex: accounts.count % DesignTokens.Palette.avatar.count
        )
        accounts[address.lowercased()] = Account(user: user, password: password)
        currentUserId = user.id
        return user.id
    }

    func sendPasswordReset(email: String) async throws {
        try await pause()
        if let forcedError { throw forcedError }
        guard accounts.keys.contains(email.lowercased().trimmingCharacters(in: .whitespaces)) else {
            // Real services stay quiet about which addresses exist; the mock
            // matches so the UI doesn't get built against a leakier contract.
            return
        }
    }

    func signOut() throws { currentUserId = nil }

    func loadUser(_ uid: UserID) async throws -> User? {
        accounts.values.first { $0.user.id == uid }?.user
    }

    private func pause() async throws {
        try await Task.sleep(for: .milliseconds(400))
    }
}
