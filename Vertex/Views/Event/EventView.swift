import SwiftUI

/// 3d–3h are one screen in different states, not five destinations. An open
/// cancel vote takes priority over everything else.
struct EventView: View {
    @Bindable var store: EventStore
    var onBack: () -> Void = {}

    @State private var proposingCancellation = false
    @State private var reason = ""

    var body: some View {
        Group {
            switch store.stage {
            case .voting:
                VotingView(store: store, onBack: onBack)
            case .draw:
                DrawView(store: store)
            case .runoff:
                RunoffView(store: store, onBack: onBack)
            case .lockedIn:
                LockedInView(store: store, onBack: onBack) { proposingCancellation = true }
            case .cancelVote:
                CancelVoteView(store: store)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: store.stage)
        .alert("Call it off?", isPresented: $proposingCancellation) {
            TextField("Why?", text: $reason)
            Button("Never mind", role: .cancel) { reason = "" }
            Button("Put it to the group") {
                store.proposeCancellation(reason: reason.isEmpty ? "No reason given" : reason)
                reason = ""
            }
        } message: {
            Text("Everyone votes. It's off once more than half agree.")
        }
    }
}

#Preview("Voting") {
    EventView(store: EventStore(detail: MockData.campingWeekend, currentUserId: MockData.ivy.id))
}

#Preview("Draw") {
    EventView(store: EventStore(detail: MockData.drawnEvent, currentUserId: MockData.ivy.id))
}

#Preview("Run-off") {
    EventView(store: EventStore(detail: MockData.runoffEvent, currentUserId: MockData.ivy.id))
}

#Preview("Locked in") {
    EventView(store: EventStore(detail: MockData.settledEvent, currentUserId: MockData.ivy.id))
}

#Preview("Cancel vote") {
    EventView(store: EventStore(detail: MockData.cancellingEvent, currentUserId: MockData.ivy.id))
}
