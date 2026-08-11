import SwiftUI

/// 2b — decided and deciding as two lists behind one segmented control, so the
/// side you aren't looking at still reports how much is on it.
struct YourEventsView: View {

    let services: Services
    var currentUser: User = MockData.ivy
    var events: EventListModel?
    var details: EventDetailsModel?
    var directory: DirectoryModel?
    @Binding var selectedTab: Tab
    var unreadNotifications: Int = 0

    /// The doc opens on the deciding side — it's the half with something to do.
    @State private var segment: EventSegment = .deciding
    @State private var planning = false
    @State private var openEventId: EventID?

    var body: some View {
        Screen {
            VStack(spacing: 0) {
                header
                    .padding(.horizontal, DesignTokens.Layout.screenPadding)
                    .padding(.top, DesignTokens.Spacing.sm)

                EventSegmentedControl(
                    selection: $segment,
                    counts: [.decided: decidedItems.count, .deciding: orderedDeciding.count]
                )
                .padding(.horizontal, DesignTokens.Layout.screenPadding)
                .padding(.top, DesignTokens.Spacing.xxxl)

                sheet
                    .padding(.top, DesignTokens.Spacing.xxxl)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: segment)
        .sheet(isPresented: $planning) {
            StartPlanningFlow(
                organiser: currentUser,
                friends: directory?.others(than: currentUser.id) ?? [],
                repository: services.events
            ) {
                planning = false
            } onCreated: { eventId in
                planning = false
                openEventId = eventId
            }
        }
        .fullScreenCover(item: $openEventId) { id in
            EventScreen(
                eventId: id,
                currentUserId: currentUser.id,
                repository: services.events
            ) {
                openEventId = nil
            }
        }
    }

    private var header: some View {
        HStack {
            Text("Your events")
                .textStyle(DesignTokens.Typography.titleLarge)
                .foregroundStyle(DesignTokens.Colors.onField)
            Spacer(minLength: DesignTokens.Spacing.xl)
            ButtonSecondary("Plan", icon: "plus") { planning = true }
        }
    }

    private var sheet: some View {
        VStack(spacing: 0) {
            list
                // 16pt gutter rather than the usual 20 — 2b's cards run wider
                // than the ones on the planning sheets.
                .padding(.horizontal, DesignTokens.Spacing.xxxl)
                .padding(.top, 18)

            TabBar(selection: $selectedTab, badges: [.notifications: unreadNotifications])
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

    @ViewBuilder
    private var list: some View {
        if isEmpty {
            VStack(spacing: 0) {
                empty
                Spacer(minLength: 0)
            }
        } else {
            VStack(spacing: 0) {
                lede
                    .textStyle(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Colors.inkSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, DesignTokens.Spacing.xs)
                    .padding(.bottom, DesignTokens.Spacing.xl)

                ScrollView {
                    LazyVStack(spacing: DesignTokens.Spacing.lg) {
                        switch segment {
                        case .decided:
                            ForEach(decidedItems) { decidedRow($0) }
                        case .deciding:
                            ForEach(orderedDeciding) { decidingCard($0) }
                        }
                    }
                    .padding(.bottom, DesignTokens.Spacing.huge)
                }
                .scrollIndicators(.hidden)
            }
        }
    }

    /// Neither empty state is in the doc — turn 2 only draws the full screen.
    private var empty: some View {
        VStack(spacing: DesignTokens.Spacing.xxl) {
            Text(segment == .decided ? "How about a beach trip?" : "All good here.")
                .textStyle(DesignTokens.Typography.bodyLargeStrong)
                .foregroundStyle(DesignTokens.Colors.inkTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 56)
    }

    // MARK: - Rows

    private func decidedRow(_ item: DecidedItem) -> some View {
        let detail = details?.detail(item.event.id)
        return Button {
            openEventId = item.event.id
        } label: {
            DecidedEventRow(
                weekday: item.start.formatted(.dateTime.weekday(.abbreviated)).uppercased(),
                day: item.start.formatted(.dateTime.day()),
                month: item.start.formatted(.dateTime.month(.abbreviated)).uppercased(),
                title: item.event.name,
                detail: "\(item.start.formatted(.dateTime.hour().minute())) · \(item.event.place)",
                attendees: detail?.going.map(\.avatar) ?? [],
                attendance: detail.map { "\($0.going.count) going" }
                    ?? "\(item.event.participantCount) in",
                relative: Self.relative(to: item.start),
                isNext: item.event.id == events?.nextUp?.id
            )
        }
        .buttonStyle(.plain)
    }

    private func decidingCard(_ event: Event) -> some View {
        Button {
            openEventId = event.id
        } label: {
            DecidingEventCard(
                title: event.name,
                mode: mode(for: event),
                needsYou: urgency(event) == .needsYou
            ) {
                openEventId = event.id
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Slicing the list

private extension YourEventsView {

    struct DecidedItem: Identifiable {
        let event: Event
        let start: Date
        var id: EventID { event.id }
    }

    /// What the card is asking of you, and the order the list runs in.
    enum Urgency: Int { case needsYou, readyToLock, waiting }

    var decidedItems: [DecidedItem] {
        (events?.decided ?? []).compactMap { event in
            event.decided.map { DecidedItem(event: event, start: $0.start) }
        }
    }

    /// Whatever wants you first, then whatever can be settled, then the rest —
    /// each by whichever closes soonest. The list's own order is by age, which
    /// buries the one event that needs a tap.
    var orderedDeciding: [Event] {
        (events?.deciding ?? []).sorted { left, right in
            let (a, b) = (urgency(left).rawValue, urgency(right).rawValue)
            if a != b { return a < b }
            return left.votingClosesAt < right.votingClosesAt
        }
    }

    var isEmpty: Bool {
        segment == .decided ? decidedItems.isEmpty : orderedDeciding.isEmpty
    }

    func urgency(_ event: Event) -> Urgency {
        guard let detail = details?.detail(event.id) else { return .waiting }
        if detail.needsVote(from: currentUser.id) { return .needsYou }
        if detail.canDecide() { return .readyToLock }
        return .waiting
    }

    /// Only the top card gets the expanded treatment — it's the one the screen
    /// is actually asking you to act on.
    var expandedId: EventID? {
        orderedDeciding.first { urgency($0) == .needsYou }?.id
    }

    func mode(for event: Event) -> DecidingEventCard.Mode {
        guard let detail = details?.detail(event.id) else {
            // Before the detail listener has delivered. The event document alone
            // knows how many people are in and nothing about their votes.
            return .waiting(fraction: 0, progress: "\(event.participantCount) in",
                            detail: "Still deciding")
        }

        let total = event.participantCount

        // Unreachable today — the planning flow creates events straight into
        // voting — but the phase is in the model, so don't render it as votes.
        if event.status == .gathering {
            let submitted = detail.submittedAvailabilityCount
            return .waiting(
                fraction: Double(submitted) / Double(max(1, total)),
                progress: "\(submitted) of \(total) in",
                detail: "Picking dates · \(Self.closes(event.availabilityClosesAt))"
            )
        }

        if detail.canDecide() {
            return .lock(
                summary: Self.lockSummary(detail),
                // A tie can't be locked in — it goes to a run-off instead.
                action: detail.isDraw() ? "Break the tie" : "Lock it in"
            )
        }

        let finished = detail.finishedVotingCount

        if event.id == expandedId {
            let best = detail.rankedSlots().first.map(detail.tally(for:))
            let slots = detail.currentRoundSlots.map { slot -> SlotSplit in
                let tally = detail.tally(for: slot)
                return SlotSplit(
                    id: slot.id,
                    label: SlotFormat.startDay(slot),
                    tally: tally,
                    isLeading: tally.cast > 0
                        && tally.yes == best?.yes && tally.no == best?.no
                )
            }
            return .vote(
                slots: slots,
                progress: "\(finished) of \(total) have voted",
                action: "Add your vote"
            )
        }

        return .waiting(
            fraction: Double(finished) / Double(max(1, total)),
            progress: "\(finished) of \(total) voted",
            detail: "\(Self.dates(detail.currentRoundSlots.count)) · \(Self.closes(event.votingClosesAt))"
        )
    }
}

// MARK: - Copy

private extension YourEventsView {

    /// "Two are waiting on **your** vote." The emphasis is the doc's.
    @ViewBuilder
    var lede: some View {
        switch segment {
        case .decided:
            // 2b only draws the deciding side; this borrows 2a's own subtitle.
            Text(decidedItems.isEmpty
                 ? "It's brewing..."
                 : "\(Self.spelled(decidedItems.count)) locked in.")
        case .deciding:
            let count = orderedDeciding.filter { urgency($0) == .needsYou }.count
            switch count {
            case 0:
                Text("It's their turn.")
            case 1:
                Text("One is waiting on \(yours) vote.")
            default:
                Text("\(Self.spelled(count)) are waiting on \(yours) vote.")
            }
        }
    }

    /// "your", picked out of the lighter sentence around it. The weight and
    /// colour ride on the run, since the line itself is set in inkSecondary.
    var yours: Text {
        Text("your")
            .font(DesignTokens.Typography.captionStrong.font)
            .foregroundColor(DesignTokens.Colors.ink)
    }

    /// "All 6 voted · Thu 4 Sep wins".
    static func lockSummary(_ detail: EventDetail) -> String {
        let total = detail.event.participantCount
        // The gate opens on unanimity *or* on the deadline, and "all n voted"
        // would be a lie in the second case.
        let who = detail.everyoneFinishedVoting ? "All \(total) voted" : "Voting closed"
        if detail.isDraw() { return "\(who) · it's a tie" }
        guard let winner = detail.leadingSlot() else { return who }
        return "\(who) · \(SlotFormat.startDay(winner)) wins"
    }

    /// "closes Friday" while that's unambiguous, "closes 12 Sep" once it isn't.
    static func closes(_ date: Date) -> String {
        guard date > .now else { return "closing now" }
        if date.timeIntervalSinceNow < 7 * 86_400 {
            return "closes \(date.formatted(.dateTime.weekday(.wide)))"
        }
        return "closes \(date.formatted(.dateTime.day().month(.abbreviated)))"
    }

    static func dates(_ count: Int) -> String {
        "\(count) date\(count == 1 ? "" : "s")"
    }

    static func relative(to date: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: .now, to: date).day ?? 0
        switch days {
        case ..<0: return "past"
        case 0: return "today"
        case 1: return "tomorrow"
        // The doc switches to weeks by 21 days and is still on days at 3.
        case 2...13: return "in \(days) days"
        default: return "in \(days / 7) wks"
        }
    }

    static func spelled(_ value: Int) -> String {
        spellOut.string(from: value as NSNumber)?.capitalized ?? "\(value)"
    }

    static let spellOut: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .spellOut
        return formatter
    }()
}

#Preview("Your Events") {
    @Previewable @State var tab: Tab = .yourEvents
    let services = Services.mock()
    let events = EventListModel(repository: services.events, uid: MockData.ivy.id)
    let details = EventDetailsModel(repository: services.events)

    YourEventsView(
        services: services,
        events: events,
        details: details,
        selectedTab: $tab
    )
    .task {
        events.connect()
        details.follow(MockData.yourEvents.map(\.event.id))
    }
}

#Preview("Nothing on") {
    @Previewable @State var tab: Tab = .yourEvents
    let services = Services(
        auth: MockAuthService(signedIn: MockData.ivy.id),
        events: MockEventRepository(seed: []),
        directory: MockEventRepository(seed: [])
    )

    YourEventsView(
        services: services,
        events: EventListModel(repository: services.events, uid: MockData.ivy.id),
        details: EventDetailsModel(repository: services.events),
        selectedTab: $tab
    )
}
