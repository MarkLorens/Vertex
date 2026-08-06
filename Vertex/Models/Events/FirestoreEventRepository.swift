import Foundation
@preconcurrency import FirebaseFirestore

/// Firestore layout, matching Vertex-DataModel.md:
///
///     events/{id}                    the event document
///     events/{id}/participants/{uid} status, snapshot, alarm, gate flags
///     events/{id}/slots/{slotId}     start, end, round, votes map
///     events/{id}/availability/{uid} the days one person marked
///
/// `participantIds` on the parent is the only denominator, and the only field
/// the list query filters on.
final class FirestoreEventRepository: EventRepository, UserDirectory, @unchecked Sendable {

    private var store: Firestore { Firestore.firestore() }

    private func events() -> CollectionReference { store.collection("events") }
    private func event(_ id: EventID) -> DocumentReference { events().document(id) }

    // MARK: - Reading

    func observeEvents(for uid: UserID) -> AsyncStream<[Event]> {
        AsyncStream { continuation in
            let registration = events()
                .whereField("participantIds", arrayContains: uid)
                .addSnapshotListener { snapshot, _ in
                    let events = snapshot?.documents.compactMap { try? $0.data(as: Event.self) } ?? []
                    continuation.yield(events)
                }
            continuation.onTermination = { _ in registration.remove() }
        }
    }

    /// Four listeners feeding one stream. Each fires independently, so the
    /// assembled detail is re-emitted whenever any part of it moves.
    func observeDetail(_ eventId: EventID) -> AsyncStream<EventDetail> {
        AsyncStream { continuation in
            let box = DetailBox()
            let document = event(eventId)

            let registrations: [ListenerRegistration] = [
                document.addSnapshotListener { snapshot, _ in
                    guard let snapshot, let event = try? snapshot.data(as: Event.self) else { return }
                    box.update(continuation) { $0.event = event }
                },
                document.collection("participants").addSnapshotListener { snapshot, _ in
                    let people = snapshot?.documents.compactMap { try? $0.data(as: Participant.self) } ?? []
                    box.update(continuation) { $0.participants = people }
                },
                document.collection("slots").addSnapshotListener { snapshot, _ in
                    let slots = snapshot?.documents.compactMap { try? $0.data(as: Slot.self) } ?? []
                    box.update(continuation) { $0.slots = slots }
                },
                document.collection("availability").addSnapshotListener { snapshot, _ in
                    let days = snapshot?.documents.compactMap { try? $0.data(as: Availability.self) } ?? []
                    box.update(continuation) { $0.availability = days }
                },
            ]
            continuation.onTermination = { _ in registrations.forEach { $0.remove() } }
        }
    }

    func observeUsers() -> AsyncStream<[User]> {
        AsyncStream { continuation in
            let registration = store.collection("users").addSnapshotListener { snapshot, _ in
                let users = snapshot?.documents.compactMap { try? $0.data(as: User.self) } ?? []
                continuation.yield(users)
            }
            continuation.onTermination = { _ in registration.remove() }
        }
    }

    /// Holds the four pieces and only emits once the event document itself has
    /// arrived — an EventDetail without its event is meaningless.
    private final class DetailBox: @unchecked Sendable {
        private var event: Event?
        private var participants: [Participant] = []
        private var slots: [Slot] = []
        private var availability: [Availability] = []
        private let lock = NSLock()

        struct Draft {
            var event: Event?
            var participants: [Participant]
            var slots: [Slot]
            var availability: [Availability]
        }

        func update(_ continuation: AsyncStream<EventDetail>.Continuation, _ mutate: (inout Draft) -> Void) {
            lock.lock()
            var draft = Draft(event: event, participants: participants, slots: slots, availability: availability)
            mutate(&draft)
            event = draft.event
            participants = draft.participants
            slots = draft.slots
            availability = draft.availability
            let snapshot = draft
            lock.unlock()

            guard let current = snapshot.event else { return }
            continuation.yield(EventDetail(
                event: current,
                participants: snapshot.participants,
                slots: snapshot.slots,
                availability: snapshot.availability
            ))
        }
    }

    // MARK: - Creating

    func create(_ detail: EventDetail) async throws {
        let batch = store.batch()
        let document = event(detail.event.id)
        try batch.setData(from: detail.event, forDocument: document)
        for participant in detail.participants {
            try batch.setData(from: participant, forDocument: document.collection("participants").document(participant.id))
        }
        for slot in detail.slots {
            try batch.setData(from: slot, forDocument: document.collection("slots").document(slot.id))
        }
        for entry in detail.availability {
            try batch.setData(from: entry, forDocument: document.collection("availability").document(entry.id))
        }
        try await batch.commit()
    }

    // MARK: - Voting

    func setVote(eventId: EventID, slotId: SlotID, uid: UserID, vote: Bool?) async throws {
        let field = "votes.\(uid)"
        try await event(eventId).collection("slots").document(slotId)
            .updateData([field: vote ?? FieldValue.delete()])
    }

    func setVotingFinished(eventId: EventID, uid: UserID, at date: Date?) async throws {
        try await event(eventId).collection("participants").document(uid)
            .updateData(["votingFinishedAt": date.map { Timestamp(date: $0) } ?? FieldValue.delete()])
    }

    func resetVotingFinished(eventId: EventID) async throws {
        let document = event(eventId)
        let people = try await document.collection("participants").getDocuments()
        let batch = store.batch()
        for person in people.documents {
            batch.updateData(["votingFinishedAt": FieldValue.delete()], forDocument: person.reference)
        }
        try await batch.commit()
    }

    // MARK: - Event state

    func setDecided(eventId: EventID, slot: Event.DecidedSlot?) async throws {
        let value: Any = try slot.map { try Firestore.Encoder().encode($0) } ?? FieldValue.delete()
        try await event(eventId).updateData(["decided": value])
    }

    func setStatus(eventId: EventID, status: Event.Status) async throws {
        try await event(eventId).updateData(["status": status.rawValue])
    }

    func setRound(eventId: EventID, round: Int, closesAt: Date) async throws {
        try await event(eventId).updateData([
            "round": round,
            "votingClosesAt": Timestamp(date: closesAt),
        ])
    }

    func addSlots(eventId: EventID, slots: [Slot]) async throws {
        let batch = store.batch()
        let collection = event(eventId).collection("slots")
        for slot in slots {
            try batch.setData(from: slot, forDocument: collection.document(slot.id))
        }
        try await batch.commit()
    }

    // MARK: - Cancelling

    func setCancellation(eventId: EventID, cancellation: Cancellation?) async throws {
        let value: Any = try cancellation.map { try Firestore.Encoder().encode($0) } ?? FieldValue.delete()
        try await event(eventId).updateData(["cancellation": value])
    }

    func setCancellationVote(eventId: EventID, uid: UserID, cancel: Bool) async throws {
        try await event(eventId).updateData(["cancellation.votes.\(uid)": cancel])
    }

    // MARK: - Participants

    func setAlarm(eventId: EventID, uid: UserID, alarm: Alarm?) async throws {
        let value: Any = try alarm.map { try Firestore.Encoder().encode($0) } ?? FieldValue.delete()
        try await event(eventId).collection("participants").document(uid)
            .updateData(["alarm": value])
    }

    func setParticipantStatus(eventId: EventID, uid: UserID, status: Participant.Status) async throws {
        try await event(eventId).collection("participants").document(uid).updateData([
            "status": status.rawValue,
            "respondedAt": Timestamp(date: .now),
        ])
    }

    /// Needs no one else's permission, which is exactly one rule: you may only
    /// pull your own uid out of `participantIds`.
    func leave(eventId: EventID, uid: UserID) async throws {
        let document = event(eventId)
        let slots = try await document.collection("slots").getDocuments()

        let batch = store.batch()
        batch.updateData(["participantIds": FieldValue.arrayRemove([uid])], forDocument: document)
        batch.updateData(["status": Participant.Status.left.rawValue],
                         forDocument: document.collection("participants").document(uid))
        batch.deleteDocument(document.collection("availability").document(uid))
        for slot in slots.documents {
            batch.updateData(["votes.\(uid)": FieldValue.delete()], forDocument: slot.reference)
        }
        batch.updateData(["cancellation.votes.\(uid)": FieldValue.delete()], forDocument: document)
        try await batch.commit()
    }
}

// MARK: - Friends

extension FirestoreEventRepository {

    func observeUser(_ uid: UserID) -> AsyncStream<User> {
        AsyncStream { continuation in
            let registration = Firestore.firestore().collection("users").document(uid)
                .addSnapshotListener { snapshot, _ in
                    guard let user = try? snapshot?.data(as: User.self) else { return }
                    continuation.yield(user)
                }
            continuation.onTermination = { _ in registration.remove() }
        }
    }

    /// Follows the friend *ids* on your own document, then re-reads whoever is
    /// on that list. Two hops, but it means a friend renaming themselves shows
    /// up without anyone writing to your record.
    func observeFriends(of uid: UserID) -> AsyncStream<[User]> {
        AsyncStream { continuation in
            let store = Firestore.firestore()
            let registration = store.collection("users").document(uid)
                .addSnapshotListener { snapshot, _ in
                    guard let me = try? snapshot?.data(as: User.self) else { return }
                    guard !me.friendIds.isEmpty else {
                        continuation.yield([])
                        return
                    }
                    Task {
                        // `in` queries cap at 30 values, so ask in chunks.
                        var found: [User] = []
                        for chunk in stride(from: 0, to: me.friendIds.count, by: 30) {
                            let slice = Array(me.friendIds[chunk..<min(chunk + 30, me.friendIds.count)])
                            let page = try? await store.collection("users")
                                .whereField(FieldPath.documentID(), in: slice).getDocuments()
                            found += page?.documents.compactMap { try? $0.data(as: User.self) } ?? []
                        }
                        continuation.yield(found.sorted { $0.username < $1.username })
                    }
                }
            continuation.onTermination = { _ in registration.remove() }
        }
    }

    func observeIncomingRequests(for uid: UserID) -> AsyncStream<[FriendRequest]> {
        requests(matching: "toUid", uid)
    }

    func observeOutgoingRequests(from uid: UserID) -> AsyncStream<[FriendRequest]> {
        requests(matching: "fromUid", uid)
    }

    /// Requests this person sent that were accepted — the source of the
    /// "X is now your friend" row.
    func observeAcceptedRequests(from uid: UserID) -> AsyncStream<[FriendRequest]> {
        AsyncStream { continuation in
            let registration = Firestore.firestore().collection("friendRequests")
                .whereField("fromUid", isEqualTo: uid)
                .whereField("status", isEqualTo: FriendRequest.Status.accepted.rawValue)
                .addSnapshotListener { snapshot, _ in
                    let requests = snapshot?.documents.compactMap { try? $0.data(as: FriendRequest.self) } ?? []
                    continuation.yield(requests.sorted { ($0.respondedAt ?? $0.createdAt) > ($1.respondedAt ?? $1.createdAt) })
                }
            continuation.onTermination = { _ in registration.remove() }
        }
    }

    /// My own participant record on one event, read once. Cheaper than a
    /// collection-group query, which would need an index created by hand.
    func participation(eventId: EventID, uid: UserID) async throws -> Participant? {
        let snapshot = try await Firestore.firestore()
            .collection("events").document(eventId)
            .collection("participants").document(uid).getDocument()
        guard snapshot.exists else { return nil }
        return try snapshot.data(as: Participant.self)
    }

    private func requests(matching field: String, _ uid: UserID) -> AsyncStream<[FriendRequest]> {
        AsyncStream { continuation in
            let registration = Firestore.firestore().collection("friendRequests")
                .whereField(field, isEqualTo: uid)
                .whereField("status", isEqualTo: FriendRequest.Status.pending.rawValue)
                .addSnapshotListener { snapshot, _ in
                    let requests = snapshot?.documents.compactMap { try? $0.data(as: FriendRequest.self) } ?? []
                    continuation.yield(requests.sorted { $0.createdAt > $1.createdAt })
                }
            continuation.onTermination = { _ in registration.remove() }
        }
    }

    func findUser(email: String) async throws -> User? {
        let address = email.trimmingCharacters(in: .whitespaces).lowercased()
        guard !address.isEmpty else { return nil }
        let matches = try await Firestore.firestore().collection("users")
            .whereField("emailLower", isEqualTo: address).limit(to: 1).getDocuments()
        return matches.documents.compactMap { try? $0.data(as: User.self) }.first
    }

    /// Bounded by construction: the id is `{from}_{to}`, so however many times
    /// Add is pressed there is exactly one document per direction — spamming
    /// rewrites it rather than piling up. The checks in front of that stop it
    /// resurrecting a settled request or shadowing one already coming the
    /// other way.
    func sendFriendRequest(from: UserID, to: UserID) async throws {
        guard from != to else { return }
        let store = Firestore.firestore()

        // Already friends — nothing to ask for.
        if let me = try? await store.collection("users").document(from).getDocument(),
           let user = try? me.data(as: User.self), user.friendIds.contains(to) {
            return
        }

        // They asked first: accept theirs instead of leaving two crossed
        // requests that each need answering.
        let reciprocalId = "\(to)_\(from)"
        if let snapshot = try? await store.collection("friendRequests").document(reciprocalId).getDocument(),
           let theirs = try? snapshot.data(as: FriendRequest.self), theirs.status == .pending {
            try await acceptFriendRequest(theirs)
            return
        }

        let id = "\(from)_\(to)"
        let document = store.collection("friendRequests").document(id)
        if let snapshot = try? await document.getDocument(),
           let existing = try? snapshot.data(as: FriendRequest.self), existing.status == .pending {
            return
        }
        let request = FriendRequest(id: id, fromUid: from, toUid: to, status: .pending,
                                    createdAt: .now, respondedAt: nil)
        try document.setData(from: request)
    }

    func acceptFriendRequest(_ request: FriendRequest) async throws {
        let store = Firestore.firestore()
        let batch = store.batch()
        batch.updateData(["friendIds": FieldValue.arrayUnion([request.fromUid])],
                         forDocument: store.collection("users").document(request.toUid))
        batch.updateData(["friendIds": FieldValue.arrayUnion([request.toUid])],
                         forDocument: store.collection("users").document(request.fromUid))
        batch.updateData([
            "status": FriendRequest.Status.accepted.rawValue,
            "respondedAt": Timestamp(date: .now),
        ], forDocument: store.collection("friendRequests").document(request.id))
        try await batch.commit()
    }

    func ignoreFriendRequest(_ request: FriendRequest) async throws {
        try await Firestore.firestore().collection("friendRequests").document(request.id)
            .updateData([
                "status": FriendRequest.Status.ignored.rawValue,
                "respondedAt": Timestamp(date: .now),
            ])
    }

    /// Mutual, so it takes two writes. A one-sided removal would leave you on
    /// their list and them off yours.
    func removeFriend(uid: UserID, friend: UserID) async throws {
        let store = Firestore.firestore()
        let batch = store.batch()
        batch.updateData(["friendIds": FieldValue.arrayRemove([friend])],
                         forDocument: store.collection("users").document(uid))
        batch.updateData(["friendIds": FieldValue.arrayRemove([uid])],
                         forDocument: store.collection("users").document(friend))
        try await batch.commit()
    }
}
