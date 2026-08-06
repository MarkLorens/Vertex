import SwiftUI

/// 3a → 3b → 3c. Presented as a sheet over the colour field, so there's no tab
/// bar and every step keeps the grab handle.
struct StartPlanningFlow: View {
    let organiser: User
    /// Everyone invitable. Real accounts once signed in — there's no friends
    /// system yet, so this is the whole directory minus yourself.
    let friends: [User]
    let repository: EventRepository
    var onCancel: () -> Void = {}
    var onCreated: (EventID) -> Void = { _ in }

    @State private var draft: EventDraft
    @State private var step: Step = .details
    @State private var sending = false
    @State private var failure: String?

    private enum Step { case details, invites, availability }

    init(
        organiser: User,
        friends: [User],
        repository: EventRepository,
        onCancel: @escaping () -> Void = {},
        onCreated: @escaping (EventID) -> Void = { _ in }
    ) {
        self.organiser = organiser
        self.friends = friends
        self.repository = repository
        self.onCancel = onCancel
        self.onCreated = onCreated
        _draft = State(initialValue: EventDraft(organiserId: organiser.id))
    }

    var body: some View {
        ZStack {
            switch step {
            case .details:
                CreateEventView(draft: draft, onCancel: onCancel) { advance(to: .invites) }
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            case .invites:
                InviteFriendsView(draft: draft, friends: friends) {
                    advance(to: .details)
                } onNext: {
                    advance(to: .availability)
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            case .availability:
                AvailabilityView(draft: draft, isSending: sending) {
                    advance(to: .invites)
                } onSend: {
                    send()
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: step)
        .alert("Couldn't create it", isPresented: Binding(
            get: { failure != nil }, set: { if !$0 { failure = nil } }
        )) {
            Button("OK", role: .cancel) { failure = nil }
        } message: {
            Text(failure ?? "")
        }
    }

    private func advance(to next: Step) {
        step = next
    }

    /// Turns the draft into an event that's open for voting. Each contiguous run
    /// of days the organiser picked becomes one slot for the group to vote on.
    private func send() {
        guard !sending else { return }
        sending = true

        let eventId = "e_\(UUID().uuidString.prefix(10))"
        let invited = friends.filter { draft.invitedIds.contains($0.id) }
        let participantIds = [organiser.id] + invited.map(\.id)

        let slots = draft.proposedRanges.enumerated().map { index, range in
            Slot(
                id: "\(eventId)_s\(index)",
                start: Calendar.current.date(bySettingHour: 17, minute: 0, second: 0, of: range.lowerBound) ?? range.lowerBound,
                end: Calendar.current.date(bySettingHour: 16, minute: 0, second: 0, of: range.upperBound) ?? range.upperBound,
                proposedBy: organiser.id
            )
        }

        let event = Event(
            id: eventId,
            name: draft.name.trimmingCharacters(in: .whitespaces),
            place: draft.place.trimmingCharacters(in: .whitespaces),
            duration: draft.duration,
            organiserId: organiser.id,
            createdAt: .now,
            status: .voting,
            availabilityClosesAt: .now,
            votingClosesAt: .now.addingTimeInterval(3 * 86_400),
            round: 1,
            participantIds: participantIds,
            decided: nil,
            cancellation: nil
        )

        // The organiser is in by definition — they proposed it. Everyone else
        // starts on `invited` until they answer.
        let participants = ([organiser] + invited).map { user in
            let isOrganiser = user.id == organiser.id
            return Participant(
                id: user.id,
                status: isOrganiser ? .going : .invited,
                username: user.username,
                avatarColorIndex: user.avatarColorIndex,
                invitedAt: .now,
                respondedAt: isOrganiser ? .now : nil,
                availabilitySubmittedAt: isOrganiser ? .now : nil,
                votingFinishedAt: nil,
                alarm: nil
            )
        }

        let detail = EventDetail(
            event: event,
            participants: participants,
            slots: slots,
            availability: [Availability(id: organiser.id, days: draft.selectedDays.sorted())]
        )

        Task {
            do {
                try await repository.create(detail)
                onCreated(eventId)
            } catch {
                failure = error.localizedDescription
            }
            sending = false
        }
    }
}

#Preview {
    StartPlanningFlow(
        organiser: MockData.ivy,
        friends: MockData.everyone.filter { $0.id != MockData.ivy.id },
        repository: MockEventRepository()
    )
}
