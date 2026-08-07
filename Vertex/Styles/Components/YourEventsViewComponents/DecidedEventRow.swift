import SwiftUI

/// A settled event: date block, what and where, who's coming, how far off.
struct DecidedEventRow: View {

    /// "SAT", "8", "AUG" — split so the block can colour each line separately.
    let weekday: String
    let day: String
    let month: String
    let title: String
    /// "8:00 PM · Ida's roof".
    let detail: String
    let attendees: [Avatar]
    /// "6 going".
    let attendance: String
    /// "in 3 days".
    let relative: String
    /// The soonest one. Only this row's date block and relative column are
    /// drawn in terracotta — it's what the Upcoming tab is counting down to.
    var isNext: Bool = false

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.xxl) {
            dateBlock

            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .textStyle(DesignTokens.Typography.bodyLargeStrong)
                    .foregroundStyle(DesignTokens.Colors.ink)
                Text(detail)
                    .textStyle(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Colors.inkSecondary)
                    .padding(.top, 3)

                HStack(spacing: DesignTokens.Spacing.md) {
                    AvatarStack(
                        avatars: attendees,
                        visibleLimit: 3,
                        diameter: DesignTokens.Size.Avatar.small,
                        ringColor: DesignTokens.Colors.card
                    )
                    Text(attendance)
                        .textStyle(DesignTokens.Typography.caption3)
                        .foregroundStyle(DesignTokens.Colors.inkTertiary)
                }
                .padding(.top, 9)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(relative)
                .textStyle(DesignTokens.Typography.caption2Strong)
                .foregroundStyle(isNext
                    ? DesignTokens.Colors.accentOnSheet
                    : DesignTokens.Colors.inkSubtle)
                .fixedSize()
        }
        .padding(.horizontal, DesignTokens.Layout.cardPadding)
        .padding(.vertical, DesignTokens.Spacing.xxl)
        .background(
            DesignTokens.Colors.card,
            in: .rect(cornerRadius: DesignTokens.Radius.card, style: .continuous)
        )
        .shadow(DesignTokens.Elevation.card)
    }

    private var dateBlock: some View {
        VStack(spacing: 1) {
            Text(weekday)
                .textStyle(DesignTokens.Typography.eyebrowSmall)
                .foregroundStyle(isNext
                    ? DesignTokens.Colors.accentOnSheet
                    : DesignTokens.Colors.inkTertiary)
            Text(day)
                .textStyle(DesignTokens.Typography.headlineTight)
                .foregroundStyle(isNext
                    ? DesignTokens.Palette.terracottaShade
                    : DesignTokens.Colors.ink)
            Text(month)
                .textStyle(DesignTokens.Typography.eyebrowSmall)
                .foregroundStyle(isNext
                    ? DesignTokens.Colors.accentOnSheet.opacity(0.8)
                    : DesignTokens.Colors.inkTertiary)
        }
        .frame(width: 48)
        .padding(.vertical, DesignTokens.Spacing.md)
        .background(
            isNext ? DesignTokens.Colors.accentTint : DesignTokens.Palette.warmGrey200,
            in: .rect(cornerRadius: DesignTokens.Radius.field, style: .continuous)
        )
    }
}

#Preview {
    VStack(spacing: DesignTokens.Spacing.lg) {
        DecidedEventRow(
            weekday: "SAT", day: "8", month: "AUG",
            title: "Sam's rooftop birthday",
            detail: "8:00 PM · Ida's roof",
            attendees: [
                Avatar(initials: "SR", colorIndex: 1),
                Avatar(initials: "JM", colorIndex: 3),
                Avatar(initials: "TO", colorIndex: 5),
                Avatar(initials: "AK", colorIndex: 7),
                Avatar(initials: "NB", colorIndex: 0),
                Avatar(initials: "DP", colorIndex: 2),
            ],
            attendance: "6 going",
            relative: "in 3 days",
            isNext: true
        )
        DecidedEventRow(
            weekday: "THU", day: "21", month: "AUG",
            title: "Ren's leaving drinks",
            detail: "7:30 PM · The Fox",
            attendees: [
                Avatar(initials: "AK", colorIndex: 7),
                Avatar(initials: "NB", colorIndex: 0),
                Avatar(initials: "DP", colorIndex: 2),
            ],
            attendance: "9 going",
            relative: "in 3 wks"
        )
    }
    .padding(DesignTokens.Spacing.xxxl)
    .frame(maxHeight: .infinity, alignment: .top)
    .background(DesignTokens.Colors.sheet)
}
