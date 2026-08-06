import SwiftUI

/// An uppercase label over a bordered field. The border turns terracotta while
/// focused, which is the only focus signal the design uses.
struct AuthField<Accessory: View>: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var isFocused: Bool = false
    var leadingSymbol: String?
    var secure: Bool = false
    @ViewBuilder var accessory: Accessory

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(label.uppercased())
                .textStyle(DesignTokens.Typography.eyebrow)
                .foregroundStyle(DesignTokens.Colors.inkSubtle)

            HStack(spacing: DesignTokens.Spacing.lg) {
                if let leadingSymbol {
                    Image(systemName: leadingSymbol)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(DesignTokens.Colors.inkFaint)
                }

                Group {
                    if secure {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                    }
                }
                .textStyle(DesignTokens.Typography.bodyLarge)
                .foregroundStyle(DesignTokens.Colors.ink)
                .tint(DesignTokens.Colors.accent)

                accessory
            }
            .padding(.horizontal, DesignTokens.Layout.controlPadding)
            .frame(height: 52)
            .background(DesignTokens.Colors.card, in: shape)
            .overlay {
                shape.strokeBorder(
                    isFocused ? DesignTokens.Colors.accent : DesignTokens.Colors.border,
                    lineWidth: isFocused ? 1.5 : 1
                )
            }
        }
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: DesignTokens.Radius.field, style: .continuous)
    }
}

extension AuthField where Accessory == EmptyView {
    init(
        label: String,
        placeholder: String,
        text: Binding<String>,
        isFocused: Bool = false,
        leadingSymbol: String? = nil,
        secure: Bool = false
    ) {
        self.init(
            label: label, placeholder: placeholder, text: text,
            isFocused: isFocused, leadingSymbol: leadingSymbol, secure: secure,
            accessory: { EmptyView() }
        )
    }
}

/// The eye that flips a password field between dots and plain text.
struct RevealButton: View {
    @Binding var isRevealed: Bool

    var body: some View {
        Button { isRevealed.toggle() } label: {
            Image(systemName: isRevealed ? "eye.slash" : "eye")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(DesignTokens.Colors.inkFaint)
        }
        .buttonStyle(.plain)
    }
}

/// Three bars and a word. Empty passwords show an untouched track rather than
/// a red warning — nobody has done anything wrong yet.
struct PasswordStrengthMeter: View {
    let strength: PasswordStrength

    private var color: Color {
        switch strength {
        case .none, .weak: DesignTokens.Colors.negative
        case .fair: DesignTokens.Colors.maybe
        case .strong: DesignTokens.Colors.positive
        }
    }

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.lg) {
            HStack(spacing: DesignTokens.Spacing.xs) {
                ForEach(0..<3, id: \.self) { index in
                    Capsule()
                        .fill(index < strength.filledBars ? color : DesignTokens.Colors.track)
                        .frame(height: DesignTokens.Size.Bar.strength)
                }
            }
            if let label = strength.label {
                Text(label)
                    .textStyle(DesignTokens.Typography.caption3)
                    .foregroundStyle(strength == .strong
                                     ? DesignTokens.Colors.positiveInk
                                     : DesignTokens.Colors.inkTertiary)
            }
        }
        .animation(.easeOut(duration: 0.2), value: strength.filledBars)
    }
}

/// "Continue with Apple" / "Continue with Google". Text-only by design — the
/// official marks are licensed assets that have to be dropped in before ship.
struct SocialButton: View {
    enum Provider: String { case apple = "Apple", google = "Google" }

    let provider: Provider
    var compact: Bool = false
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Text(compact ? provider.rawValue : "Continue with \(provider.rawValue)")
                .textStyle(DesignTokens.Typography.bodyLargeStrong)
                .foregroundStyle(provider == .apple
                                 ? DesignTokens.Colors.onField
                                 : DesignTokens.Colors.ink)
                .frame(maxWidth: .infinity)
                .frame(height: compact ? 48 : DesignTokens.Size.buttonHeightSecondary)
                .background {
                    let shape = RoundedRectangle(cornerRadius: compact ? 14 : 15, style: .continuous)
                    if provider == .apple {
                        shape.fill(DesignTokens.Colors.actionInk)
                    } else {
                        shape
                            .fill(DesignTokens.Colors.card)
                            .overlay(shape.strokeBorder(DesignTokens.Colors.borderStrong))
                    }
                }
        }
        .buttonStyle(.plain)
    }
}

/// A hairline either side of a short label — "OR", "OR SIGN UP WITH EMAIL".
struct OrDivider: View {
    let title: String

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.xl) {
            DesignTokens.Colors.separator.frame(height: 1)
            Text(title.uppercased())
                .textStyle(DesignTokens.Typography.caption3)
                .tracking(0.3)
                .foregroundStyle(DesignTokens.Colors.inkFaint)
                .fixedSize()
            DesignTokens.Colors.separator.frame(height: 1)
        }
    }
}

#Preview {
    VStack(spacing: DesignTokens.Spacing.huge) {
        AuthField(label: "Email", placeholder: "you@example.com", text: .constant("ivy.marsh@hey.com"),
                  isFocused: true, leadingSymbol: "envelope")
        PasswordStrengthMeter(strength: .strong)
        PasswordStrengthMeter(strength: .weak)
        OrDivider(title: "or")
        SocialButton(provider: .apple)
        SocialButton(provider: .google)
    }
    .padding()
    .background(DesignTokens.Colors.sheet)
}
