import SwiftUI

// MARK: - Component
struct ButtonSecondary: View {

    /// The two sizes the design uses.
    enum Size {
        /// 34pt — the standard chip. `+ Start Planning`, `+ Plan`.
        case regular
        /// 30pt — trailing a list row, where 34pt would crowd the row. `Vote`.
        case small
    }

    private let title: String
    private let icon: String?
    private let size: Size
    private let action: () -> Void

    init(
        _ title: String,
        icon: String? = nil,
        size: Size = .regular,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.size = size
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: size.spacing) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: size.iconSize, weight: .bold))
                        .foregroundStyle(DesignTokens.Colors.accentIcon)
                }
                Text(title)
                    .textStyle(size.textStyle)
                    .foregroundStyle(DesignTokens.Colors.accentInk)
            }
        }
        .buttonStyle(ButtonSecondaryStyle(size: size, hasIcon: icon != nil))
    }
}

// MARK: - Style

struct ButtonSecondaryStyle: ButtonStyle {

    var size: ButtonSecondary.Size = .regular
    var hasIcon: Bool = false

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.leading, hasIcon ? size.leadingPaddingWithIcon : size.horizontalPadding)
            .padding(.trailing, size.horizontalPadding)
            .frame(height: size.height)
            .background(DesignTokens.Colors.card, in: Capsule())
            // The doc's chips set `flex-shrink: 0` — they never compress to fit
            // a row, the content next to them gives way instead.
            .fixedSize(horizontal: true, vertical: false)
            // Pressed and disabled states aren't specified in the design doc;
            // these are conventional defaults, not imported values.
            .opacity(configuration.isPressed ? 0.75 : 1)
            .opacity(isEnabled ? 1 : 0.4)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Metrics

private extension ButtonSecondary.Size {

    /// 34pt / 30pt.
    var height: CGFloat {
        switch self {
        case .regular: DesignTokens.Size.pillHeight
        case .small: DesignTokens.Size.chipHeight
        }
    }

    /// 14pt semibold for `.regular`, 13.5pt semibold for `.small` — both at -0.1 tracking.
    var textStyle: DesignTokens.TextStyle {
        switch self {
        case .regular: DesignTokens.Typography.link
        case .small: DesignTokens.Typography.captionStrong
        }
    }

    /// 14pt on both sides, before the icon adjustment.
    var horizontalPadding: CGFloat {
        DesignTokens.Spacing.xxl
    }

    /// 11pt — the doc's leading inset when an icon is present.
    /// (`.small` with an icon doesn't appear in the doc; this keeps the ratio.)
    var leadingPaddingWithIcon: CGFloat {
        switch self {
        case .regular: 11
        case .small: 10
        }
    }

    /// 6pt between icon and label.
    var spacing: CGFloat {
        switch self {
        case .regular: DesignTokens.Spacing.sm
        case .small: 5
        }
    }

    /// 13pt glyph, matching the doc's 13×13 SVG.
    var iconSize: CGFloat {
        switch self {
        case .regular: 13
        case .small: 12
        }
    }
}

// MARK: - Previews

#Preview() {
    VStack() {
        ButtonSecondary("Start Planning", icon: "plus") {}
        ButtonSecondary("Vote", icon: "plus") {}
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DesignTokens.Colors.field)
}
