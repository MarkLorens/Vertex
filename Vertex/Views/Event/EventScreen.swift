import SwiftUI

/// Loads an event by id and keeps it live, then hands it to `EventView`.
/// Presented from a list, which only has the event document — the detail
/// screens need participants and slots too.
struct EventScreen: View {
    let eventId: EventID
    let currentUserId: UserID
    let repository: EventRepository
    var onClose: () -> Void = {}

    @State private var store: EventStore?

    var body: some View {
        ZStack {
            if let store {
                EventView(store: store, onBack: onClose)
            } else {
                DesignTokens.Colors.field
                    .ignoresSafeArea()
                    .overlay {
                        ProgressView().tint(DesignTokens.Colors.onField)
                    }
            }
        }
        .task(id: eventId) {
            for await detail in repository.observeDetail(eventId) {
                if Task.isCancelled { return }
                if let store {
                    store.receive(detail)
                } else {
                    let fresh = EventStore(
                        detail: detail, currentUserId: currentUserId, repository: repository
                    )
                    store = fresh
                }
            }
        }
    }
}

#Preview {
    EventScreen(
        eventId: MockData.campingWeekend.event.id,
        currentUserId: MockData.ivy.id,
        repository: MockEventRepository()
    )
}
