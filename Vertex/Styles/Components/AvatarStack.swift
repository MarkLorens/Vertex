import SwiftUI

struct Avatar: Identifiable {
    let id = UUID()
    let initials: String
    /// Index into `DesignTokens.Palette.avatar`, wrapped. In real use this
    /// should come from a stable hash of the person, not their position in
    /// the list — the colour has to survive the group being re-sorted.
    let colorIndex: Int

    var color: Color {
        let palette = DesignTokens.Palette.avatar
        return palette[abs(colorIndex) % palette.count]
    }
}

struct AvatarStack: View {

    let avatars: [Avatar]
    /// Anyone past this many becomes a "+n" chip.
    var visibleLimit: Int = 4
    var diameter: CGFloat = DesignTokens.Size.Avatar.xlarge
    /// The colour the separating ring is cut in — whatever the stack sits on.
    var ringColor: Color = DesignTokens.Colors.sheet

    private var visible: [Avatar] { Array(avatars.prefix(visibleLimit)) }
    private var overflow: Int { max(0, avatars.count - visibleLimit) }

    /// 2pt at 30pt across, 1.5pt at the smaller sizes the doc uses elsewhere.
    private var ringWidth: CGFloat { diameter >= 30 ? 2 : DesignTokens.Size.Avatar.ringWidth }

    var body: some View {
        HStack(spacing: DesignTokens.Size.Avatar.overlapLarge) {
            ForEach(visible) { avatar in
                circle(fill: avatar.color) {
                    Text(avatar.initials)
                        .textStyle(DesignTokens.Typography.avatarInitials)
                        .foregroundStyle(DesignTokens.Colors.onField)
                }
            }
            if overflow > 0 {
                circle(fill: DesignTokens.Colors.avatarEmpty) {
                    Text("+\(overflow)")
                        // A point smaller than initials so "+2" doesn't crowd the ring.
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(DesignTokens.Colors.inkStrong)
                }
            }
        }
    }

    private func circle<Label: View>(fill: Color, @ViewBuilder label: () -> Label) -> some View {
        label()
            .frame(width: diameter, height: diameter)
            .background(fill, in: .circle)
            // The ring sits outside the colour, as the doc's CSS border does —
            // inset it and every avatar loses 2×ringWidth of its diameter.
            .padding(ringWidth)
            .background(ringColor, in: .circle)
    }
}

#Preview {
    HStack(spacing: DesignTokens.Spacing.huge) {
        AvatarStack(avatars: [
            Avatar(initials: "SR", colorIndex: 1),
            Avatar(initials: "JM", colorIndex: 3),
            Avatar(initials: "TO", colorIndex: 5),
            Avatar(initials: "AK", colorIndex: 7),
            Avatar(initials: "NB", colorIndex: 0),
            Avatar(initials: "DP", colorIndex: 2),
        ])
        AvatarStack(
            avatars: [Avatar(initials: "SR", colorIndex: 1), Avatar(initials: "JM", colorIndex: 3)],
            diameter: DesignTokens.Size.Avatar.medium
        )
    }
    .padding()
    .background(DesignTokens.Colors.sheet)
}
