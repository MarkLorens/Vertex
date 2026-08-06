import Foundation
import Observation

/// One row on the Notifications tab. Nothing is stored in a notifications
/// collection — every row is derived from a record that already exists, so
/// nothing has to be written twice or kept in step.
enum NotificationItem: Identifiable, Equatable {
    case friendRequest(FriendRequest, from: User)
    case friendAccepted(FriendRequest, friend: User)
    case eventInvite(Event, organiser: User?, status: Participant.Status)

    var id: String {
        switch self {
        case .friendRequest(let request, _): "fr_\(request.id)"
        case .friendAccepted(let request, _): "fa_\(request.id)"
        case .eventInvite(let event, _, _): "ev_\(event.id)"
        }
    }

    var timestamp: Date {
        switch self {
        case .friendRequest(let request, _): request.createdAt
        case .friendAccepted(let request, _): request.respondedAt ?? request.createdAt
        case .eventInvite(let event, _, _): event.createdAt
        }
    }

    /// Actionable rows sit under "New", settled ones under "Earlier". That's the
    /// whole rule — there's no read state to track.
    var needsAction: Bool {
        switch self {
        case .friendRequest: true
        case .friendAccepted: false
        case .eventInvite(_, _, let status): status == .invited
        }
    }
}

@Observable
final class NotificationsModel {
    private(set) var items: [NotificationItem] = []

    private let directory: UserDirectory
    private let events: EventListModel
    private let uid: UserID

    private var incoming: [FriendRequest] = []
    private var accepted: [FriendRequest] = []
    private var users: [UserID: User] = [:]
    private var participation: [EventID: Participant.Status] = [:]
    private var subscriptions: [Task<Void, Never>] = []

    init(directory: UserDirectory, events: EventListModel, uid: UserID) {
        self.directory = directory
        self.events = events
        self.uid = uid
    }

    var actionable: [NotificationItem] { items.filter(\.needsAction) }
    var earlier: [NotificationItem] { items.filter { !$0.needsAction } }
    var badgeCount: Int { actionable.count }

    func connect() {
        guard subscriptions.isEmpty else { return }
        subscriptions = [
            Task { [weak self, directory] in
                for await users in directory.observeUsers() {
                    guard !Task.isCancelled else { return }
                    await MainActor.run {
                        self?.users = Dictionary(uniqueKeysWithValues: users.map { ($0.id, $0) })
                        self?.rebuild()
                    }
                }
            },
            Task { [weak self, directory, uid] in
                for await requests in directory.observeIncomingRequests(for: uid) {
                    guard !Task.isCancelled else { return }
                    await MainActor.run {
                        self?.incoming = requests
                        self?.rebuild()
                    }
                }
            },
            Task { [weak self, directory, uid] in
                for await requests in directory.observeAcceptedRequests(from: uid) {
                    guard !Task.isCancelled else { return }
                    await MainActor.run {
                        self?.accepted = requests
                        self?.rebuild()
                    }
                }
            },
        ]
    }

    deinit { subscriptions.forEach { $0.cancel() } }

    /// Reads my own participant record per event. One-shot rather than a
    /// collection-group listener, which would need a hand-made index for a
    /// handful of documents.
    func refreshParticipation() async {
        var found: [EventID: Participant.Status] = [:]
        for event in events.events {
            if let mine = try? await directory.participation(eventId: event.id, uid: uid) {
                found[event.id] = mine.status
            }
        }
        participation = found
        rebuild()
    }

    private func rebuild() {
        var built: [NotificationItem] = []

        for request in incoming where request.status == .pending {
            guard let sender = users[request.fromUid] else { continue }
            built.append(.friendRequest(request, from: sender))
        }

        // Only recent acceptances — this is a feed, not an archive.
        let cutoff = Date.now.addingTimeInterval(-14 * 86_400)
        for request in accepted where (request.respondedAt ?? request.createdAt) > cutoff {
            guard let friend = users[request.toUid] else { continue }
            built.append(.friendAccepted(request, friend: friend))
        }

        for event in events.events {
            guard event.organiserId != uid, let status = participation[event.id] else { continue }
            guard status == .invited || status == .going else { continue }
            built.append(.eventInvite(event, organiser: users[event.organiserId], status: status))
        }

        items = built.sorted { $0.timestamp > $1.timestamp }
    }
}
