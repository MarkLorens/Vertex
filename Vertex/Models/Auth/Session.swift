import Foundation
import Observation

/// Who's signed in, and the one place the rest of the app asks.
@Observable
final class Session {
    enum State: Equatable {
        case restoring
        case signedOut
        case signedIn(User)
    }

    private(set) var state: State = .restoring
    private(set) var isWorking = false
    var error: AuthError?

    private let auth: AuthProviding

    init(auth: AuthProviding) {
        self.auth = auth
    }

    var user: User? {
        if case .signedIn(let user) = state { return user }
        return nil
    }

    var userId: UserID? { user?.id }

    /// Called once at launch. Firebase restores its own session, so an existing
    /// uid means we only need the profile document.
    func restore() async {
        guard let uid = auth.currentUserId else {
            state = .signedOut
            return
        }
        if let user = try? await auth.loadUser(uid) {
            state = .signedIn(user)
        } else {
            // Signed in with no profile record — treat as signed out rather than
            // letting a half-built account into the app.
            try? auth.signOut()
            state = .signedOut
        }
    }

    func signIn(email: String, password: String) async {
        await run {
            let uid = try await auth.signIn(email: email, password: password)
            guard let user = try await auth.loadUser(uid) else {
                throw AuthError.other("Signed in, but your profile is missing.")
            }
            state = .signedIn(user)
        }
    }

    func register(email: String, password: String, username: String) async {
        await run {
            let uid = try await auth.register(email: email, password: password, username: username)
            guard let user = try await auth.loadUser(uid) else {
                throw AuthError.other("Account created, but your profile didn't save.")
            }
            state = .signedIn(user)
        }
    }

    @discardableResult
    func sendPasswordReset(email: String) async -> Bool {
        await run {
            try await auth.sendPasswordReset(email: email)
        }
    }

    func signOut() {
        try? auth.signOut()
        state = .signedOut
    }

    /// Wraps every call so the spinner and the error banner behave the same way
    /// everywhere, and a thrown non-AuthError still surfaces something readable.
    @discardableResult
    private func run(_ work: () async throws -> Void) async -> Bool {
        isWorking = true
        error = nil
        defer { isWorking = false }
        do {
            try await work()
            return true
        } catch let authError as AuthError {
            error = authError
            return false
        } catch {
            self.error = .other(error.localizedDescription)
            return false
        }
    }
}
