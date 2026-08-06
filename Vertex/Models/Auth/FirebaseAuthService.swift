import Foundation
import FirebaseAuth
@preconcurrency import FirebaseFirestore

/// The only file in the app that imports Firebase. Everything else goes through
/// `AuthProviding`, which keeps the views buildable and previewable without it.
final class FirebaseAuthService: AuthProviding, @unchecked Sendable {

    private var store: Firestore { Firestore.firestore() }

    var currentUserId: UserID? { Auth.auth().currentUser?.uid }

    func signIn(email: String, password: String) async throws -> UserID {
        do {
            let result = try await Auth.auth().signIn(
                withEmail: email.trimmingCharacters(in: .whitespaces),
                password: password
            )
            return result.user.uid
        } catch {
            throw Self.translate(error)
        }
    }

    /// Two writes that have to succeed together. If the profile can't be saved
    /// the auth account is deleted again — an account with no `users/{uid}` is
    /// invisible to every other screen, and leaving one behind also blocks the
    /// address from being reused.
    func register(email: String, password: String, username: String) async throws -> UserID {
        let address = email.trimmingCharacters(in: .whitespaces)

        let result: AuthDataResult
        do {
            result = try await Auth.auth().createUser(withEmail: address, password: password)
        } catch {
            throw Self.translate(error)
        }

        let uid = result.user.uid
        // Colour is assigned once and stored, so a later rename doesn't change
        // how someone's avatar looks to the rest of the group.
        let user = User(
            id: uid,
            email: address,
            username: username.trimmingCharacters(in: .whitespaces),
            avatarColorIndex: abs(uid.hashValue) % DesignTokens.Palette.avatar.count
        )

        do {
            let payload = try Firestore.Encoder().encode(user)
            // Firestore retries a failing write forever rather than erroring, so
            // without a deadline a missing database just hangs the sign-up.
            try await Self.withTimeout(seconds: 12) { [store] in
                try await store.collection("users").document(uid).setData(payload)
            }
            return uid
        } catch {
            try? await result.user.delete()
            if error is AuthError { throw error }
            throw AuthError.other("Account couldn't be saved: \(error.localizedDescription)")
        }
    }

    private static func withTimeout<T: Sendable>(
        seconds: Double,
        _ work: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask { try await work() }
            group.addTask {
                try await Task.sleep(for: .seconds(seconds))
                throw AuthError.network
            }
            guard let first = try await group.next() else { throw AuthError.network }
            group.cancelAll()
            return first
        }
    }

    /// Firebase emails a reset *link*, not a six-digit code — see the note in
    /// AuthFlow about why the code screens aren't on the default path.
    func sendPasswordReset(email: String) async throws {
        do {
            try await Auth.auth().sendPasswordReset(
                withEmail: email.trimmingCharacters(in: .whitespaces)
            )
        } catch {
            throw Self.translate(error)
        }
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }

    func loadUser(_ uid: UserID) async throws -> User? {
        let snapshot = try await store.collection("users").document(uid).getDocument()
        guard snapshot.exists else { return nil }
        return try snapshot.data(as: User.self)
    }

    private static func translate(_ error: Error) -> AuthError {
        guard let code = AuthErrorCode(rawValue: (error as NSError).code) else {
            return .other(error.localizedDescription)
        }
        switch code {
        case .invalidEmail: return .invalidEmail
        case .weakPassword: return .weakPassword
        case .wrongPassword, .invalidCredential: return .wrongPassword
        case .userNotFound: return .userNotFound
        case .emailAlreadyInUse: return .emailInUse
        case .networkError: return .network
        default: return .other(error.localizedDescription)
        }
    }
}
