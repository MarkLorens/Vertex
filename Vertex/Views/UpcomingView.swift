import SwiftUI

struct UpcomingView: View {

    let services: Services
    var currentUser: User = MockData.ivy
    var events: EventListModel?
    var directory: DirectoryModel?
    @Binding var selectedTab: Tab
    var onSignOut: () -> Void = {}
    var unreadNotifications: Int = 0

    @State private var planning = false
    @State private var openEventId: EventID?
    /// The full detail for whatever Upcoming is counting down to. The list query
    /// only carries event documents; the card needs participants too.
    @State private var nextDetail: EventDetail?
    @State private var nextDetailTask: Task<Void, Never>?

    private var nextEvent: Event? { events?.nextUp }

    /// The screen only has something to show when there's an event *and* it has
    /// a settled date — unwrapping both once keeps the two branches below simple.
    private var next: (detail: EventDetail, start: Date)? {
        guard let nextDetail, let decided = nextDetail.event.decided else { return nil }
        return (nextDetail, decided.start)
    }

    var body: some View {
        Screen {
            VStack(spacing: 0) {
                header
                    .padding(.horizontal, DesignTokens.Layout.screenPadding)
                    .padding(.top, DesignTokens.Spacing.md)

                Spacer(minLength: 0)

                countdown
                    .padding(.horizontal, DesignTokens.Layout.heroPadding)

                Spacer(minLength: 0)

                sheet
            }
        }
        .task(id: nextEvent?.id) { await followNextEvent() }
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
            // Long-press the wordmark to sign out — there's no Profile tab yet,
            // and two-device testing needs a way back to the sign-in screen.
            IconStyle()
                .onLongPressGesture(minimumDuration: 0.6, perform: onSignOut)
            Spacer()
            ButtonSecondary("Start Planning", icon: "plus") { planning = true }
        }
    }

    @ViewBuilder
    private var countdown: some View {
        if let next {
            // Re-evaluated every second so the seconds column actually moves.
            TimelineView(.periodic(from: .now, by: 1)) { context in
                let remaining = Countdown(until: next.start, from: context.date)
                UpcomingCountdown(
                    lede: Self.lede(days: remaining.days),
                    title: next.detail.event.name,
                    days: remaining.days,
                    hours: remaining.hours,
                    minutes: remaining.minutes,
                    seconds: remaining.seconds
                )
            }
        } else {
            UpcomingCountdownEmpty()
        }
    }

    @ViewBuilder
    private var card: some View {
        if let next {
            Button {
                openEventId = next.detail.event.id
            } label: {
                UpcomingEventCard(
                    when: Self.when(next.start),
                    place: next.detail.event.place,
                    // Constant here — the card only renders for a settled event.
                    status: "Agreed",
                    attendees: next.detail.going.map(\.avatar),
                    attendanceSummary: Self.attendance(next.detail)
                )
            }
            .buttonStyle(.plain)
        } else {
            UpcomingEventCardEmpty(onStartPlanning: { planning = true })
        }
    }

    private var sheet: some View {
        VStack(spacing: 0) {
            card
                .padding(.horizontal, DesignTokens.Layout.sheetPaddingWide)
                .padding(.top, DesignTokens.Layout.sheetPadding)
                .padding(.bottom, 13)

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

    /// Follows whichever event is next. Re-subscribes when that changes, and
    /// drops the detail entirely when there's nothing coming up.
    private func followNextEvent() async {
        nextDetailTask?.cancel()
        guard let id = nextEvent?.id else {
            nextDetail = nil
            return
        }
        for await detail in services.events.observeDetail(id) {
            if Task.isCancelled { return }
            nextDetail = detail
        }
    }
}

// MARK: - Copy

private extension UpcomingView {
    /// The doc only ever shows "Three sleeps until", so everything but that case
    /// is invented — swap freely.
    static func lede(days: Int) -> String {
        switch days {
        case 0: "Later today"
        case 1: "One sleep until"
        case 2...9: "\(spelled(days)) sleeps until"
        default: "\(days) sleeps until"
        }
    }

    static func spelled(_ value: Int) -> String {
        spellOut.string(from: value as NSNumber)?.capitalized ?? "\(value)"
    }

    /// "Sat 8 Aug · 8:00 PM". Weekday is formatted separately because asking for
    /// it alongside day+month makes most locales insert a comma the design
    /// doesn't have. Day order and 12/24h still follow the device.
    static func when(_ date: Date) -> String {
        let weekday = date.formatted(.dateTime.weekday(.abbreviated))
        let dayMonth = date.formatted(.dateTime.day().month(.abbreviated))
        let time = date.formatted(.dateTime.hour().minute())
        return "\(weekday) \(dayMonth) · \(time)"
    }

    /// "6 going, Nina's thinking" — anyone still on `invited` hasn't answered.
    static func attendance(_ detail: EventDetail) -> String {
        let going = "\(detail.going.count) going"
        let thinking = detail.undecided
        switch thinking.count {
        case 0: return going
        case 1: return "\(going), \(firstName(thinking[0].username))'s thinking"
        default: return "\(going), \(thinking.count) thinking"
        }
    }

    static func firstName(_ username: String) -> String {
        username.split(separator: " ").first.map(String.init) ?? username
    }

    static let spellOut: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .spellOut
        return formatter
    }()
}

extension String: @retroactive Identifiable {
    public var id: String { self }
}

#Preview("Upcoming") {
    RootView(services: .mock())
}

#Preview("Nothing on") {
    RootView(services: Services(
        auth: MockAuthService(signedIn: MockData.ivy.id),
        events: MockEventRepository(seed: []),
        directory: MockEventRepository(seed: [])
    ))
}
