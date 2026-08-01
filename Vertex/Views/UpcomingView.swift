import SwiftUI

struct UpcomingView: View {

    @State private var selectedTab: Tab = .upcoming

    private let attendees = [
        Avatar(initials: "SR", colorIndex: 1),
        Avatar(initials: "JM", colorIndex: 3),
        Avatar(initials: "TO", colorIndex: 5),
        Avatar(initials: "AK", colorIndex: 7),
        Avatar(initials: "NB", colorIndex: 0),
        Avatar(initials: "DP", colorIndex: 2),
    ]

    var body: some View {
        Screen {
            VStack(spacing: 0) {
                header
                    .padding(.horizontal, DesignTokens.Layout.screenPadding)
                    .padding(.top, DesignTokens.Spacing.md)

                Spacer(minLength: 0)

//                UpcomingCountdown(
//                    lede: "Three sleeps until",
//                    title: "Sam's rooftop\nbirthday",
//                    days: 3, hours: 14, minutes: 22, seconds: 8
//                )
                UpcomingCountdownEmpty()
                .padding(.horizontal, DesignTokens.Layout.heroPadding)

                Spacer(minLength: 0)

                sheet
            }
        }
    }

    private var header: some View {
        HStack {
            IconStyle()
            Spacer()
            ButtonSecondary("Start Planning", icon: "plus") {}
        }
    }

    private var sheet: some View {
        VStack(spacing: 0) {
//            UpcomingEventCard(
//                when: "Sat 8 Aug · 8:00 PM",
//                place: "Ida's roof · 14 Lark St",
//                status: "Agreed",
//                attendees: attendees,
//                attendanceSummary: "6 going, Nina's thinking"
//            )
            UpcomingEventCardEmpty()
            .padding(.horizontal, DesignTokens.Layout.sheetPaddingWide)
            .padding(.top, DesignTokens.Layout.sheetPadding)
            .padding(.bottom, 13)

            TabBar(selection: $selectedTab, badges: [.notifications: 2])
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

#Preview {
    UpcomingView()
}
