import SwiftUI

// MARK: - Component

struct ButtonPrimary: View {

    enum Size {
        /// 54pt, full width — the confirm at the bottom of a sheet.
        case large
        /// 38pt, fills its share of a row — paired with a second action.
        case medium
        /// 30pt pill, hugs — a chip trailing a row. Matches `ButtonSecondary.small`.
        case small
    }

    private let title: String
    private let icon: String?
    private let iconEdge: HorizontalEdge
    private let size: Size
    private let action: () -> Void

    init(
        _ title: String,
        icon: String? = nil,
        iconEdge: HorizontalEdge = .leading,
        size: Size = .large,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.iconEdge = iconEdge
        self.size = size
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: size.spacing) {
                if iconEdge == .leading { iconView }
                Text(title).textStyle(size.textStyle)
                if iconEdge == .trailing { iconView }
            }
        }
        .buttonStyle(ButtonPrimaryStyle(size: size))
    }

    @ViewBuilder
    private var iconView: some View {
        if let icon {
            Image(systemName: icon)
                .font(.system(size: size.iconSize, weight: .bold))
        }
    }
}

// MARK: - Style

struct ButtonPrimaryStyle: ButtonStyle {

    var size: ButtonPrimary.Size = .large

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isEnabled ? DesignTokens.Colors.onField : DesignTokens.Colors.inkFaint)
            .padding(.horizontal, size.horizontalPadding)
            .frame(maxWidth: size.fillsWidth ? .infinity : nil)
            .frame(height: size.height)
            .background(
                isEnabled ? DesignTokens.Colors.accent : DesignTokens.Colors.separator,
                in: size.shape
            )
            // `.small` is the only size the doc lets hug its label; the others
            // are laid out full width by their container.
            .fixedSize(horizontal: !size.fillsWidth, vertical: false)
            // The disabled pair is imported (5d "Verify" before the code is
            // complete). The pressed state is not in the doc — it's a default.
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Metrics

private extension ButtonPrimary.Size {

    /// 54 / 38 / 30pt.
    var height: CGFloat {
        switch self {
        case .large: DesignTokens.Size.buttonHeight
        case .medium: 38
        case .small: DesignTokens.Size.chipHeight
        }
    }

    /// 17pt semibold, 14.5pt semibold, 13.5pt semibold.
    var textStyle: DesignTokens.TextStyle {
        switch self {
        case .large: DesignTokens.Typography.button
        case .medium: DesignTokens.Typography.footnoteStrong
        case .small: DesignTokens.Typography.captionStrong
        }
    }

    /// 17pt and 12pt corners are continuous — the iOS squircle the doc is
    /// drawing with a plain CSS radius.
    var shape: AnyShape {
        switch self {
        case .large: AnyShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.button, style: .continuous))
        case .medium: AnyShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.chip, style: .continuous))
        case .small: AnyShape(Capsule())
        }
    }

    /// `.large` and `.medium` are centred in the width their container gives them.
    var fillsWidth: Bool {
        switch self {
        case .large, .medium: true
        case .small: false
        }
    }

    /// Only the hugging chip needs its own inset.
    var horizontalPadding: CGFloat {
        switch self {
        case .large, .medium: 0
        case .small: DesignTokens.Spacing.xxl
        }
    }

    /// 8pt between icon and label on the full-width button.
    var spacing: CGFloat {
        switch self {
        case .large: DesignTokens.Spacing.md
        case .medium: DesignTokens.Spacing.sm
        case .small: 5
        }
    }

    /// The doc sets a 16pt leading plus and a 15pt trailing chevron; 16pt for
    /// both, since SF Symbols already optically size the two differently.
    var iconSize: CGFloat {
        switch self {
        case .large: 16
        case .medium: 14
        case .small: 12
        }
    }
}

// MARK: - Previews

#Preview {
    VStack(spacing: DesignTokens.Spacing.lg) {
        ButtonPrimary("Sign in") {}
        ButtonPrimary("Next · Invite friends", icon: "chevron.right", iconEdge: .trailing) {}
        ButtonPrimary("Start Planning", icon: "plus") {}
        ButtonPrimary("Verify") {}.disabled(true)

        HStack(spacing: DesignTokens.Spacing.md) {
            ButtonPrimary("I'm in", size: .medium) {}
            ButtonSecondary("Not this time", size: .small) {}
        }

        HStack(spacing: DesignTokens.Spacing.md) {
            ButtonPrimary("Vote", size: .small) {}
            ButtonPrimary("Respond", size: .small) {}
        }
    }
    .padding(DesignTokens.Layout.sheetPaddingWide)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    .background(DesignTokens.Colors.sheet)
}
