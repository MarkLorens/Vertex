import SwiftUI

/// The grab handle at the top of a modal sheet.
struct SheetHandle: View {
    var body: some View {
        Capsule()
            .fill(DesignTokens.Colors.onFieldFaint)
            .frame(width: 38, height: 5)
            .frame(maxWidth: .infinity)
    }
}

/// Cancel/Back · step dots · Next/Send — the chrome on the three creation sheets.
struct StepNav: View {
    let leading: String
    let trailing: String
    /// Zero-based.
    let step: Int
    let stepCount: Int
    /// The forward action greys out until the step is satisfied.
    var trailingEnabled: Bool = true
    var onLeading: () -> Void = {}
    var onTrailing: () -> Void = {}

    var body: some View {
        HStack {
            Button(leading, action: onLeading)
                .textStyle(DesignTokens.Typography.body)
                .foregroundStyle(DesignTokens.Colors.onFieldSecondary)

            Spacer()

            HStack(spacing: 5) {
                ForEach(0..<stepCount, id: \.self) { index in
                    Circle()
                        .fill(index == step
                              ? DesignTokens.Colors.onField
                              : DesignTokens.Colors.onField.opacity(0.35))
                        .frame(width: 7, height: 7)
                }
            }

            Spacer()

            Button(trailing, action: onTrailing)
                .textStyle(DesignTokens.Typography.body)
                .foregroundStyle(trailingEnabled
                                 ? DesignTokens.Colors.onFieldSecondary
                                 : DesignTokens.Colors.onField.opacity(0.35))
                .disabled(!trailingEnabled)
        }
        .buttonStyle(.plain)
    }
}

/// Back · title · overflow — the chrome on an event's own screens.
struct EventNav: View {
    let title: String
    var showsOverflow: Bool = true
    var onBack: () -> Void = {}
    var onOverflow: () -> Void = {}

    var body: some View {
        ZStack {
            Text(title)
                .textStyle(DesignTokens.Typography.navTitle)
                .foregroundStyle(DesignTokens.Colors.onFieldStrong)

            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(DesignTokens.Colors.onField)
                }
                Spacer()
                Button(action: onOverflow) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(DesignTokens.Colors.onFieldSecondary)
                }
                .opacity(showsOverflow ? 1 : 0)
                .disabled(!showsOverflow)
            }
        }
        .buttonStyle(.plain)
    }
}

/// A pill that is either chosen or not — "A whole weekend", "2 hours before".
struct ChoiceChip: View {
    let title: String
    let isSelected: Bool
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Text(title)
                .textStyle(isSelected
                           ? DesignTokens.Typography.footnoteStrong
                           : DesignTokens.Typography.footnoteMedium)
                .foregroundStyle(isSelected
                                 ? DesignTokens.Colors.onField
                                 : DesignTokens.Colors.inkStrong)
                .padding(.horizontal, 15)
                .padding(.vertical, 9)
                .background {
                    if isSelected {
                        Capsule().fill(DesignTokens.Colors.accent)
                    } else {
                        Capsule()
                            .fill(DesignTokens.Colors.card)
                            .overlay(Capsule().strokeBorder(DesignTokens.Colors.separator))
                    }
                }
        }
        .buttonStyle(.plain)
    }
}

/// An uppercase label with a rule running to the edge — "YOUR TIMES".
struct RuledLabel: View {
    let title: String

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            Text(title.uppercased())
                .textStyle(DesignTokens.Typography.eyebrow)
                .foregroundStyle(DesignTokens.Colors.inkSubtle)
            DesignTokens.Colors.track
                .frame(height: DesignTokens.Size.hairline)
        }
    }
}

#Preview {
    VStack(spacing: DesignTokens.Spacing.huge) {
        SheetHandle()
        StepNav(leading: "Cancel", trailing: "Next", step: 0, stepCount: 3, trailingEnabled: false)
        EventNav(title: "Camping weekend")
        HStack(spacing: DesignTokens.Spacing.md) {
            ChoiceChip(title: "An hour", isSelected: false)
            ChoiceChip(title: "A whole weekend", isSelected: true)
        }
        RuledLabel(title: "Your times")
    }
    .padding()
    .frame(maxHeight: .infinity)
    .background(DesignTokens.Colors.field)
}
