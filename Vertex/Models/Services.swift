import Foundation
import Observation

/// Everything the app talks to the outside world through. One object so swapping
/// the whole backend for mocks is a single line at the root.
struct Services {
    let auth: AuthProviding
    let events: EventRepository
    let directory: UserDirectory

    static func mock(signedIn: UserID? = MockData.ivy.id) -> Services {
        let repository = MockEventRepository()
        return Services(
            auth: MockAuthService(signedIn: signedIn),
            events: repository,
            directory: repository
        )
    }
}

/// The signed-in user's events, kept live. Owns the list query and hands out
/// whichever slice a screen needs.
@Observable
final class EventListModel {
    private(set) var events: [Event] = []
    private(set) var hasLoaded = false

    private let repository: EventRepository
    private let uid: UserID
    private var subscription: Task<Void, Never>?

    init(repository: EventRepository, uid: UserID) {
        self.repository = repository
        self.uid = uid
    }

    func connect() {
        guard subscription == nil else { return }
        subscription = Task { [weak self, repository, uid] in
            for await events in repository.observeEvents(for: uid) {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self?.events = events
                    self?.hasLoaded = true
                }
            }
        }
    }

    deinit { subscription?.cancel() }

    var decided: [Event] {
        events.filter { $0.status == .decided }
            .sorted { ($0.decided?.start ?? .distantFuture) < ($1.decided?.start ?? .distantFuture) }
    }

    var deciding: [Event] {
        events.filter { $0.isDeciding }.sorted { $0.createdAt > $1.createdAt }
    }

    /// The soonest settled event that hasn't already happened — what Upcoming
    /// counts down to.
    var nextUp: Event? {
        decided.first { ($0.decided?.start ?? .distantPast) > .now }
    }
}

/// The assembled detail for every event in the list, kept live. The list query
/// only carries event documents; Your Events needs slots and participants for
/// every row, not just the one it's counting down to.
@Observable
final class EventDetailsModel {
    private(set) var details: [EventID: EventDetail] = [:]

    private let repository: EventRepository
    private var subscriptions: [EventID: Task<Void, Never>] = [:]

    init(repository: EventRepository) {
        self.repository = repository
    }

    func detail(_ id: EventID) -> EventDetail? { details[id] }

    /// Subscribes to anything new and drops anything gone. Idempotent, so it can
    /// be called on every change to the list.
    @MainActor
    func follow(_ ids: [EventID]) {
        let wanted = Set(ids)
        for (id, subscription) in subscriptions where !wanted.contains(id) {
            subscription.cancel()
            subscriptions[id] = nil
            details[id] = nil
        }
        for id in wanted where subscriptions[id] == nil {
            subscriptions[id] = Task { [weak self, repository] in
                for await detail in repository.observeDetail(id) {
                    guard !Task.isCancelled else { return }
                    await MainActor.run { self?.details[id] = detail }
                }
            }
        }
    }

    deinit { subscriptions.values.forEach { $0.cancel() } }
}

/// Everyone with an account. Stands in for a friends list until there is one.
@Observable
final class DirectoryModel {
    private(set) var users: [User] = []
    private(set) var friends: [User] = []
    private(set) var incomingRequests: [FriendRequest] = []

    private let directory: UserDirectory
    private let uid: UserID
    private var subscriptions: [Task<Void, Never>] = []

    init(directory: UserDirectory, uid: UserID) {
        self.directory = directory
        self.uid = uid
    }

    func connect() {
        guard subscriptions.isEmpty else { return }
        subscriptions = [
            Task { [weak self, directory] in
                for await users in directory.observeUsers() {
                    guard !Task.isCancelled else { return }
                    await MainActor.run { self?.users = users }
                }
            },
            Task { [weak self, directory, uid] in
                for await friends in directory.observeFriends(of: uid) {
                    guard !Task.isCancelled else { return }
                    await MainActor.run { self?.friends = friends }
                }
            },
            Task { [weak self, directory, uid] in
                for await requests in directory.observeIncomingRequests(for: uid) {
                    guard !Task.isCancelled else { return }
                    await MainActor.run { self?.incomingRequests = requests }
                }
            },
        ]
    }

    deinit { subscriptions.forEach { $0.cancel() } }

    func others(than uid: UserID) -> [User] {
        users.filter { $0.id != uid }.sorted { $0.username < $1.username }
    }

    func user(_ uid: UserID) -> User? { users.first { $0.id == uid } }
}
