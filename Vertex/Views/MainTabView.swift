import SwiftUI

/// The tab bar is drawn inside each screen's cream sheet rather than over the
/// top, so this holds the selection and every screen renders its own.
struct MainTabView: View {
    let services: Services
    let user: User
    let events: EventListModel
    let directory: DirectoryModel
    var onSignOut: () -> Void = {}

    @State private var selectedTab: Tab = .upcoming
    @State private var route: Route?
    @State private var notifications: NotificationsModel
    @State private var pendingRequest: (FriendRequest, User)?
    @State private var pendingDecline: (Event, User?)?
    @State private var openEventId: EventID?

    init(services: Services, user: User, events: EventListModel,
         directory: DirectoryModel, onSignOut: @escaping () -> Void = {}) {
        self.services = services
        self.user = user
        self.events = events
        self.directory = directory
        self.onSignOut = onSignOut
        _notifications = State(initialValue: NotificationsModel(
            directory: services.directory, events: events, uid: user.id
        ))
    }

    private enum Route: Identifiable {
        case friends, addFriend
        var id: Int { self == .friends ? 0 : 1 }
    }

    private func resolve(_ request: FriendRequest, accept: Bool) {
        pendingRequest = nil
        Task {
            if accept {
                try? await services.directory.acceptFriendRequest(request)
            } else {
                try? await services.directory.ignoreFriendRequest(request)
            }
        }
    }

    private func respond(to event: Event, going: Bool) {
        Task {
            try? await services.events.setParticipantStatus(
                eventId: event.id, uid: user.id, status: going ? .going : .declined
            )
            await notifications.refreshParticipation()
        }
    }

    var body: some View {
        ZStack {
            switch selectedTab {
            case .upcoming:
                UpcomingView(
                    services: services,
                    currentUser: user,
                    events: events,
                    directory: directory,
                    selectedTab: $selectedTab,
                    onSignOut: onSignOut,
                    unreadNotifications: notifications.badgeCount
                )

            case .profile:
                ProfileView(
                    user: directory.user(user.id) ?? user,
                    selectedTab: $selectedTab,
                    friends: directory.friends,
                    unreadNotifications: notifications.badgeCount,
                    onOpenFriends: { route = .friends },
                    onAddFriend: { route = .addFriend },
                    onSignOut: onSignOut
                )

            case .notifications:
                NotificationsView(
                    model: notifications,
                    selectedTab: $selectedTab,
                    onPlan: { selectedTab = .upcoming },
                    onRespondToRequest: { request, sender in pendingRequest = (request, sender) },
                    onJoin: { event in respond(to: event, going: true) },
                    onDecline: { event, organiser in pendingDecline = (event, organiser) },
                    onOpenEvent: { event in openEventId = event.id }
                )

            case .yourEvents:
                ComingSoonTab(tab: selectedTab, selection: $selectedTab,
                              unread: notifications.badgeCount)
            }
        }
        .task { notifications.connect() }
        .task(id: events.events.map(\.id)) { await notifications.refreshParticipation() }
        .overlay {
            if let (request, sender) = pendingRequest {
                FriendRequestDialog(
                    sender: sender,
                    onAccept: { resolve(request, accept: true) },
                    onIgnore: { resolve(request, accept: false) },
                    onDismiss: { pendingRequest = nil }
                )
            } else if let (event, organiser) = pendingDecline {
                DeclineInviteDialog(
                    event: event, organiser: organiser,
                    onDecline: {
                        respond(to: event, going: false)
                        pendingDecline = nil
                    },
                    onDismiss: { pendingDecline = nil }
                )
            }
        }
        .animation(.easeInOut(duration: 0.2), value: pendingRequest?.0.id)
        .animation(.easeInOut(duration: 0.2), value: pendingDecline?.0.id)
        .fullScreenCover(item: $openEventId) { id in
            EventScreen(eventId: id, currentUserId: user.id, repository: services.events) {
                openEventId = nil
            }
        }
        .fullScreenCover(item: $route) { destination in
            switch destination {
            case .friends:
                FriendsListView(
                    friends: directory.friends,
                    onBack: { route = nil },
                    onAddFriend: { route = .addFriend },
                    onRemove: { friend in
                        Task { try? await services.directory.removeFriend(uid: user.id, friend: friend.id) }
                    }
                )
            case .addFriend:
                AddFriendView(
                    currentUser: user,
                    directory: services.directory,
                    friendIds: Set(directory.friends.map(\.id)),
                    onClose: { route = nil }
                )
            }
        }
    }
}

/// Placeholder for the two tabs that don't have screens yet — better than a tab
/// that silently does nothing when you press it.
struct ComingSoonTab: View {
    let tab: Tab
    @Binding var selection: Tab
    var unread: Int = 0

    var body: some View {
        Screen {
            VStack(spacing: 0) {
                Text(tab.title)
                    .textStyle(DesignTokens.Typography.titleLarge)
                    .foregroundStyle(DesignTokens.Colors.onField)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, DesignTokens.Layout.screenPadding)
                    .padding(.top, DesignTokens.Spacing.sm)

                Spacer()

                VStack(spacing: DesignTokens.Spacing.xl) {
                    Image(systemName: "hammer")
                        .font(.system(size: 34, weight: .light))
                    Text("Not built yet")
                        .textStyle(DesignTokens.Typography.bodyLargeStrong)
                }
                .foregroundStyle(DesignTokens.Colors.onFieldFaint)

                Spacer()

                VStack(spacing: 0) {
                    Color.clear.frame(height: DesignTokens.Spacing.xxl)
                    TabBar(selection: $selection, badges: [.notifications: unread])
                }
                .background {
                    UnevenRoundedRectangle(
                        topLeadingRadius: DesignTokens.Radius.sheet,
                        topTrailingRadius: DesignTokens.Radius.sheet
                    )
                    .fill(DesignTokens.Colors.sheet)
                    .ignoresSafeArea(edges: .bottom)
                }
            }
        }
    }
}

#Preview {
    RootView(services: .mock())
}
