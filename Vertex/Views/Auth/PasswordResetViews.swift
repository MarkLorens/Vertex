import SwiftUI
import Combine

/// 5c — ask for the address. The copy follows whichever reset style is in play,
/// because promising a code and sending a link is the kind of small lie users
/// remember.
struct ForgotPasswordView: View {
    @Bindable var session: Session
    let style: PasswordResetStyle
    @Binding var email: String
    var onBack: () -> Void = {}
    var onSent: () -> Void = {}

    @FocusState private var focused: Bool

    private var canSubmit: Bool { Credentials.isValidEmail(email) && !session.isWorking }

    var body: some View {
        AuthScaffold {
            AuthStepHeader(step: 0, onBack: onBack) {
                Text("Forgotten it?\nHappens.")
                    .textStyle(DesignTokens.Typography.titleLarge)
                    .foregroundStyle(DesignTokens.Colors.onField)
                    .lineSpacing(-4)

                Text(style.prompt)
                    .textStyle(DesignTokens.Typography.subtitle)
                    .foregroundStyle(DesignTokens.Colors.onFieldMuted)
                    .lineSpacing(3)
                    .frame(maxWidth: 300, alignment: .leading)
                    .padding(.top, DesignTokens.Spacing.lg)
            }
        } sheet: {
            AuthField(
                label: "Email", placeholder: "you@example.com", text: $email,
                isFocused: focused, leadingSymbol: "envelope"
            )
            .textInputAutocapitalization(.never)
            .keyboardType(.emailAddress)
            .textContentType(.emailAddress)
            .focused($focused)
            .onSubmit(submit)

            Text(style.reassurance)
                .textStyle(DesignTokens.Typography.caption)
                .foregroundStyle(DesignTokens.Colors.inkTertiary)
                .lineSpacing(3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, DesignTokens.Spacing.xl)

            if let error = session.error {
                AuthErrorBanner(message: error.localizedDescription)
                    .padding(.top, DesignTokens.Spacing.xxl)
            }

            Spacer(minLength: DesignTokens.Spacing.huge)

            ButtonPrimary(session.isWorking ? "Sending…" : style.sendTitle, action: submit)
                .disabled(!canSubmit)

            Button("Back to sign in", action: onBack)
                .textStyle(DesignTokens.Typography.footnoteStrong)
                .foregroundStyle(DesignTokens.Colors.inkSecondary)
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .padding(.top, DesignTokens.Spacing.xxxl)
        }
        .onAppear { focused = true }
    }

    private func submit() {
        guard canSubmit else { return }
        Task {
            if await session.sendPasswordReset(email: email) { onSent() }
        }
    }
}

/// 5d — six boxes. Only reachable on the `.code` reset style, which needs a
/// backend that mints and checks codes; Firebase alone can't do it.
struct VerificationCodeView: View {
    let email: String
    var onBack: () -> Void = {}
    var onVerified: () -> Void = {}
    var onResend: () -> Void = {}

    @State private var code = ""
    @State private var secondsUntilResend = 42
    @FocusState private var focused: Bool

    private let length = 6
    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        AuthScaffold {
            AuthStepHeader(step: 1, onBack: onBack) {
                Text("Check your inbox")
                    .textStyle(DesignTokens.Typography.titleLarge)
                    .foregroundStyle(DesignTokens.Colors.onField)

                (Text("Sent to \(email)").fontWeight(.semibold).foregroundColor(DesignTokens.Colors.onField))
                    .textStyle(DesignTokens.Typography.subtitle)
                    .foregroundStyle(DesignTokens.Colors.onFieldMuted)
                    .padding(.top, DesignTokens.Spacing.lg)
            }
        } sheet: {
            CodeEntry(code: $code, length: length, isFocused: focused)
                .focused($focused)

            HStack(spacing: DesignTokens.Spacing.sm) {
                Text("Nothing yet?")
                    .textStyle(DesignTokens.Typography.footnote)
                    .foregroundStyle(DesignTokens.Colors.inkTertiary)
                if secondsUntilResend > 0 {
                    Text("Resend in 0:\(String(format: "%02d", secondsUntilResend))")
                        .textStyle(DesignTokens.Typography.footnoteStrong)
                        .foregroundStyle(DesignTokens.Colors.inkFaint)
                        .monospacedDigit()
                } else {
                    Button("Resend it") {
                        secondsUntilResend = 42
                        onResend()
                    }
                    .textStyle(DesignTokens.Typography.footnoteStrong)
                    .foregroundStyle(DesignTokens.Colors.accentInk)
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, DesignTokens.Spacing.huge)

            Spacer(minLength: DesignTokens.Spacing.huge)

            ButtonPrimary("Verify", action: onVerified)
                .disabled(code.count < length)

            Button("Wrong address? Start again", action: onBack)
                .textStyle(DesignTokens.Typography.footnoteStrong)
                .foregroundStyle(DesignTokens.Colors.inkSecondary)
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .padding(.top, DesignTokens.Spacing.xxxl)
        }
        .onAppear { focused = true }
        .onReceive(tick) { _ in
            if secondsUntilResend > 0 { secondsUntilResend -= 1 }
        }
    }
}

/// 5e — set the new one, then straight back to sign in.
struct NewPasswordView: View {
    var onBack: () -> Void = {}
    var onSaved: (String) -> Void = { _ in }

    @State private var password = ""
    @State private var confirmation = ""
    @State private var reveal = false
    @FocusState private var focus: Field?

    private enum Field { case password, confirmation }

    private var matches: Bool { !confirmation.isEmpty && password == confirmation }
    private var canSubmit: Bool { Credentials.isValidPassword(password) && matches }

    var body: some View {
        AuthScaffold {
            AuthStepHeader(step: 2, onBack: onBack) {
                HStack(spacing: DesignTokens.Spacing.md) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .heavy))
                    Text("CODE ACCEPTED")
                        .textStyle(DesignTokens.Typography.eyebrow)
                }
                .foregroundStyle(DesignTokens.Colors.onField)
                .padding(.bottom, DesignTokens.Spacing.xl)

                Text("Pick a new one")
                    .textStyle(DesignTokens.Typography.titleLarge)
                    .foregroundStyle(DesignTokens.Colors.onField)

                Text("Then we'll drop you back at sign in.")
                    .textStyle(DesignTokens.Typography.subtitle)
                    .foregroundStyle(DesignTokens.Colors.onFieldMuted)
                    .padding(.top, DesignTokens.Spacing.md)
            }
        } sheet: {
            AuthField(
                label: "New password", placeholder: "At least 8 characters", text: $password,
                isFocused: focus == .password, secure: !reveal
            ) {
                RevealButton(isRevealed: $reveal)
            }
            .textContentType(.newPassword)
            .focused($focus, equals: .password)

            PasswordStrengthMeter(strength: Credentials.strength(of: password))
                .padding(.top, DesignTokens.Spacing.lg)
                .padding(.bottom, DesignTokens.Spacing.huge)

            AuthField(
                label: "Again, to be sure", placeholder: "Type it once more", text: $confirmation,
                isFocused: focus == .confirmation, secure: !reveal
            )
            .textContentType(.newPassword)
            .focused($focus, equals: .confirmation)
            .onSubmit(submit)

            if !confirmation.isEmpty, !matches {
                Text("Those two don't match.")
                    .textStyle(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Colors.negativeInk)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, DesignTokens.Spacing.md)
            }

            Spacer(minLength: DesignTokens.Spacing.huge)

            ButtonPrimary("Save and sign in", action: submit)
                .disabled(!canSubmit)
        }
        .onAppear { focus = .password }
    }

    private func submit() {
        guard canSubmit else { return }
        onSaved(password)
    }
}

// MARK: - Shared pieces

/// Back chevron, three step dots, and whatever the screen wants to say.
struct AuthStepHeader<Content: View>: View {
    let step: Int
    var onBack: () -> Void = {}
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                HStack(spacing: 5) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(index == step
                                  ? DesignTokens.Colors.onField
                                  : DesignTokens.Colors.onField.opacity(0.35))
                            .frame(width: 7, height: 7)
                    }
                }
                HStack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 19, weight: .semibold))
                            .foregroundStyle(DesignTokens.Colors.onField)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
            }
            .padding(.bottom, DesignTokens.Spacing.xhuge)

            content
        }
    }
}

/// Six boxes over one hidden field — the OS keyboard and one-time-code autofill
/// only cooperate with a real text field, so the boxes are decoration.
struct CodeEntry: View {
    @Binding var code: String
    var length: Int = 6
    var isFocused: Bool = false

    var body: some View {
        ZStack {
            TextField("", text: $code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .foregroundStyle(.clear)
                .tint(.clear)
                .onChange(of: code) { _, new in
                    code = String(new.filter(\.isNumber).prefix(length))
                }

            HStack(spacing: DesignTokens.Spacing.md) {
                ForEach(0..<length, id: \.self) { index in
                    box(at: index)
                }
            }
            .allowsHitTesting(false)
        }
    }

    private func box(at index: Int) -> some View {
        let characters = Array(code)
        let isCursor = isFocused && index == characters.count
        return ZStack {
            if index < characters.count {
                Text(String(characters[index]))
                    .textStyle(DesignTokens.Typography.titleSmall)
                    .foregroundStyle(DesignTokens.Colors.ink)
                    .monospacedDigit()
            } else if isCursor {
                Capsule()
                    .fill(DesignTokens.Colors.accent)
                    .frame(width: 2, height: 26)
            }
        }
        // Flexible width with a fixed height. `aspectRatio(_:.fit)` on top of a
        // `maxWidth: .infinity` frame collapses the box to nothing instead.
        .frame(maxWidth: .infinity)
        .frame(height: 60)
        .background(DesignTokens.Colors.card, in: shape)
        .overlay {
            shape.strokeBorder(
                isCursor ? DesignTokens.Colors.accent : DesignTokens.Colors.border,
                lineWidth: isCursor ? 1.5 : 1
            )
        }
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: DesignTokens.Radius.field, style: .continuous)
    }
}

#Preview("5c Forgot") {
    ForgotPasswordView(session: Session(auth: MockAuthService()), style: .code, email: .constant(""))
}

#Preview("5d Code") {
    VerificationCodeView(email: "ivy.marsh@hey.com")
}

#Preview("5e New password") {
    NewPasswordView()
}
