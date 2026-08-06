import Foundation

/// The auth surface the views talk to. Firebase lives behind this so the rest
/// of the app — and the previews — compile and run without it.
protocol AuthProviding: Sendable {
    var currentUserId: UserID? { get }

    func signIn(email: String, password: String) async throws -> UserID
    /// Creates the account and its `users/{uid}` record together; a Firebase
    /// user with no profile document would be invisible to every other screen.
    func register(email: String, password: String, username: String) async throws -> UserID
    func sendPasswordReset(email: String) async throws
    func signOut() throws

    func loadUser(_ uid: UserID) async throws -> User?
}

enum AuthError: LocalizedError, Equatable {
    case invalidEmail
    case weakPassword
    case wrongPassword
    case userNotFound
    case emailInUse
    case network
    case notConfigured(String)
    case other(String)

    var errorDescription: String? {
        switch self {
        case .invalidEmail: "That doesn't look like an email address."
        case .weakPassword: "Passwords need at least 8 characters."
        case .wrongPassword: "That password doesn't match."
        case .userNotFound: "No account on that address."
        case .emailInUse: "There's already an account on that address."
        case .network: "Can't reach the server. Check your connection."
        case .notConfigured(let what): what
        case .other(let message): message
        }
    }
}

/// The rules the sign-up screens enforce before anything is sent.
enum Credentials {
    static func isValidEmail(_ email: String) -> Bool {
        let trimmed = email.trimmingCharacters(in: .whitespaces)
        guard let at = trimmed.firstIndex(of: "@"), at != trimmed.startIndex else { return false }
        let domain = trimmed[trimmed.index(after: at)...]
        return domain.contains(".") && !domain.hasPrefix(".") && !domain.hasSuffix(".")
            && !trimmed.contains(" ")
    }

    /// The doc's own bar — "At least 8 characters".
    static let minimumPasswordLength = 8

    static func isValidPassword(_ password: String) -> Bool {
        password.count >= minimumPasswordLength
    }

    /// Drives the three-bar meter on 5b and 5e.
    static func strength(of password: String) -> PasswordStrength {
        guard !password.isEmpty else { return .none }
        guard password.count >= minimumPasswordLength else { return .weak }
        var classes = 0
        if password.rangeOfCharacter(from: .lowercaseLetters) != nil { classes += 1 }
        if password.rangeOfCharacter(from: .uppercaseLetters) != nil { classes += 1 }
        if password.rangeOfCharacter(from: .decimalDigits) != nil { classes += 1 }
        if password.rangeOfCharacter(from: .punctuationCharacters.union(.symbols)) != nil { classes += 1 }
        if password.count >= 12, classes >= 3 { return .strong }
        return classes >= 2 ? .fair : .weak
    }
}

enum PasswordStrength {
    case none, weak, fair, strong

    var filledBars: Int {
        switch self {
        case .none: 0
        case .weak: 1
        case .fair: 2
        case .strong: 3
        }
    }

    var label: String? {
        switch self {
        case .none: nil
        case .weak: "Weak"
        case .fair: "Getting there"
        case .strong: "Strong"
        }
    }
}
