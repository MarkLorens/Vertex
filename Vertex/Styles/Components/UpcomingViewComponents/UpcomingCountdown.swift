import SwiftUI

struct UpcomingCountdown: View {

    let lede: String
    let title: String
    let days: Int
    let hours: Int
    let minutes: Int
    let seconds: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(lede)
                .textStyle(DesignTokens.Typography.lede)
                .foregroundStyle(DesignTokens.Colors.onFieldMuted)
                .padding(.bottom, 2)

            Text(title)
                .textStyle(DesignTokens.Typography.titleXLarge)
                .foregroundStyle(DesignTokens.Colors.onField)
                // line-height 1.08 against SF's natural ~1.2 at this size.
                .lineSpacing(-4)
                .padding(.bottom, 18)

            HStack(alignment: .firstTextBaseline, spacing: DesignTokens.Spacing.sm) {
                Text(pad(days))
                    .textStyle(DesignTokens.Typography.countdownHero)
                    .foregroundStyle(DesignTokens.Colors.onField)
                Text("d")
                    .textStyle(DesignTokens.Typography.countdownUnit)
                    .foregroundStyle(DesignTokens.Colors.onField.opacity(0.66))
                    .padding(.bottom, 8)
            }

            HStack(alignment: .firstTextBaseline, spacing: DesignTokens.Spacing.xxl) {
                unit(hours, "h", opacity: 0.9)
                unit(minutes, "m", opacity: 0.72)
                unit(seconds, "s", opacity: 0.5)
            }
            .padding(.top, DesignTokens.Spacing.lg)
        }
        .monospacedDigit()
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func unit(_ value: Int, _ suffix: String, opacity: Double) -> some View {
        Text("\(pad(value))\(suffix)")
            .textStyle(DesignTokens.Typography.countdownSecondary)
            .foregroundStyle(DesignTokens.Colors.onField.opacity(opacity))
    }

    private func pad(_ value: Int) -> String {
        String(format: "%02d", value)
    }
}

#Preview {
    UpcomingCountdown(
        lede: "Three sleeps until",
        title: "Sam's rooftop\nbirthday",
        days: 3, hours: 14, minutes: 22, seconds: 8
    )
    .padding(.horizontal, DesignTokens.Layout.heroPadding)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DesignTokens.Colors.field)
}
