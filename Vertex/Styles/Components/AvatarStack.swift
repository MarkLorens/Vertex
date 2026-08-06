import SwiftUI

struct Avatar: Identifiable, Hashable {
    /// The person's uid where there is one. A fresh UUID per render would churn
    /// `ForEach` identity every time a stack is rebuilt from model data.
    let id: String
    let initials: String
    /// Index into `DesignTokens.Palette.avatar`, wrapped.
    let colorIndex: Int

    init(id: String? = nil, initials: String, colorIndex: Int) {
        self.id = id ?? initials
        self.initials = initials
        self.colorIndex = colorIndex
    }

    var color: Color {
        let palette = DesignTokens.Palette.avatar
        return palette[abs(colorIndex) % palette.count]
    }
}

struct AvatarView: View {
    let avatar: Avatar
    var diameter: CGFloat = DesignTokens.Size.Avatar.xlarge
    /// The colour the separating ring is cut in. Nil for avatars that stand
    /// alone — only overlapping stacks need to be told apart.
    var ringColor: Color?

    var body: some View {
        Text(avatar.initials)
            .font(.system(size: Self.initialsSize(for: diameter), weight: .semibold))
            .foregroundStyle(DesignTokens.Colors.onField)
            .frame(width: diameter, height: diameter)
            .background(avatar.color, in: .circle)
            .ringed(ringColor, diameter: diameter)
    }

    /// The doc sets initials at roughly 38% of the circle — 11.5pt at 30, 10.5
    /// at 28, 9.5 at 24. A fixed size looks bloated on the smaller avatars.
    static func initialsSize(for diameter: CGFloat) -> CGFloat {
        (diameter * 0.385).rounded(.toNearestOrEven)
    }
}

/// A "+3" chip closing an avatar stack.
struct AvatarOverflow: View {
    let count: Int
    var diameter: CGFloat = DesignTokens.Size.Avatar.xlarge
    var ringColor: Color?

    var body: some View {
        Text("+\(count)")
            .font(.system(size: AvatarView.initialsSize(for: diameter) - 0.5, weight: .semibold))
            .foregroundStyle(DesignTokens.Colors.inkStrong)
            .frame(width: diameter, height: diameter)
            .background(DesignTokens.Colors.avatarEmpty, in: .circle)
            .ringed(ringColor, diameter: diameter)
    }
}

struct AvatarStack: View {

    let avatars: [Avatar]
    /// Anyone past this many becomes a "+n" chip.
    var visibleLimit: Int = 4
    var diameter: CGFloat = DesignTokens.Size.Avatar.xlarge
    var ringColor: Color = DesignTokens.Colors.sheet

    private var visible: [Avatar] { Array(avatars.prefix(visibleLimit)) }
    private var overflow: Int { max(0, avatars.count - visibleLimit) }

    private var overlap: CGFloat {
        diameter >= 28 ? DesignTokens.Size.Avatar.overlapLarge : DesignTokens.Size.Avatar.overlap
    }

    var body: some View {
        HStack(spacing: overlap) {
            ForEach(visible) { avatar in
                AvatarView(avatar: avatar, diameter: diameter, ringColor: ringColor)
            }
            if overflow > 0 {
                AvatarOverflow(count: overflow, diameter: diameter, ringColor: ringColor)
            }
        }
    }
}

private extension View {
    /// The ring sits outside the colour, as the doc's CSS border does — inset it
    /// and every avatar loses 2×ringWidth of its diameter.
    @ViewBuilder
    func ringed(_ color: Color?, diameter: CGFloat) -> some View {
        if let color {
            let width: CGFloat = diameter >= 30 ? 2 : DesignTokens.Size.Avatar.ringWidth
            self.padding(width).background(color, in: .circle)
        } else {
            self
        }
    }
}

#Preview {
    VStack(spacing: DesignTokens.Spacing.huge) {
        AvatarStack(avatars: [
            Avatar(initials: "SR", colorIndex: 1), Avatar(initials: "JM", colorIndex: 3),
            Avatar(initials: "TO", colorIndex: 5), Avatar(initials: "AK", colorIndex: 7),
            Avatar(initials: "NB", colorIndex: 0), Avatar(initials: "DP", colorIndex: 2),
        ])
        HStack(spacing: DesignTokens.Spacing.md) {
            AvatarView(avatar: Avatar(initials: "RK", colorIndex: 4), diameter: 38)
            AvatarView(avatar: Avatar(initials: "DP", colorIndex: 2), diameter: 28)
            AvatarView(avatar: Avatar(initials: "NB", colorIndex: 0), diameter: 22)
        }
    }
    .padding()
    .background(DesignTokens.Colors.sheet)
}
