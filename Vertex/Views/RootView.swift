import SwiftUI

struct RootView: View {
    let services: Services
    @State private var session: Session

    init(services: Services) {
        self.services = services
        _session = State(initialValue: Session(auth: services.auth))
    }

    var body: some View {
        ZStack {
            switch session.state {
            case .restoring:
                // Firebase restores its own session, so this is usually a frame
                // or two — the field colour keeps it from flashing white.
                DesignTokens.Colors.field.ignoresSafeArea()

            case .signedOut:
                AuthFlow(session: session)
                    .transition(.opacity)

            case .signedIn(let user):
                SignedInView(services: services, user: user) { session.signOut() }
                    // Rebuilt per user, so switching accounts starts clean
                    // listeners rather than reusing the last person's.
                    .id(user.id)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: session.state)
        .task { await session.restore() }
    }
}

/// Owns the live queries for whoever is signed in.
struct SignedInView: View {
    let services: Services
    let user: User
    var onSignOut: () -> Void = {}

    @State private var events: EventListModel
    @State private var directory: DirectoryModel

    init(services: Services, user: User, onSignOut: @escaping () -> Void = {}) {
        self.services = services
        self.user = user
        self.onSignOut = onSignOut
        _events = State(initialValue: EventListModel(repository: services.events, uid: user.id))
        _directory = State(initialValue: DirectoryModel(directory: services.directory, uid: user.id))
    }

    var body: some View {
        MainTabView(
            services: services,
            user: user,
            events: events,
            directory: directory,
            onSignOut: onSignOut
        )
        .onAppear {
            events.connect()
            directory.connect()
        }
    }
}

#Preview("Signed out") {
    RootView(services: .mock(signedIn: nil))
}

#Preview("Signed in") {
    RootView(services: .mock())
}
