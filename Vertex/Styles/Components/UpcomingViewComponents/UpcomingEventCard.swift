import SwiftUI

struct UpcomingEventCard: View {

    let when: String
    let place: String
    let status: String
    let attendees: [Avatar]
    let attendanceSummary: String

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(when)
                        .textStyle(DesignTokens.Typography.rowTitle)
                        .foregroundStyle(DesignTokens.Colors.ink)
                    Text(place)
                        .textStyle(DesignTokens.Typography.footnote)
                        .foregroundStyle(DesignTokens.Colors.ink.opacity(0.55))
                }
                Spacer(minLength: DesignTokens.Spacing.xl)
                StatusPill(title: status)
            }
            .padding(.bottom, DesignTokens.Spacing.xxl)

            DesignTokens.Colors.ink.opacity(0.09)
                .frame(height: DesignTokens.Size.hairline)
                .padding(.bottom, DesignTokens.Spacing.xxl)

            HStack(spacing: DesignTokens.Spacing.lg) {
                AvatarStack(avatars: attendees)
                Text(attendanceSummary)
                    .textStyle(DesignTokens.Typography.footnoteSmall)
                    .foregroundStyle(DesignTokens.Colors.ink.opacity(0.55))
                Spacer(minLength: 0)
            }
        }
    }
}

#Preview {
    UpcomingEventCard(
        when: "Sat 8 Aug · 8:00 PM",
        place: "Ida's roof · 14 Lark St",
        status: "Agreed",
        attendees: [
            Avatar(initials: "SR", colorIndex: 1),
            Avatar(initials: "JM", colorIndex: 3),
            Avatar(initials: "TO", colorIndex: 5),
            Avatar(initials: "AK", colorIndex: 7),
            Avatar(initials: "NB", colorIndex: 0),
            Avatar(initials: "DP", colorIndex: 2),
        ],
        attendanceSummary: "6 going, Nina's thinking"
    )
    .padding(.horizontal, DesignTokens.Layout.sheetPaddingWide)
    .padding(.vertical, DesignTokens.Layout.sheetPadding)
    .background(DesignTokens.Colors.sheet)
}
