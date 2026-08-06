import SwiftUI

/// 5b — email, password, username. The username field says outright that it
/// doesn't have to be unique, rather than validating for uniqueness.
struct RegisterView: View {
    @Bindable var session: Session
    var onBack: () -> Void = {}
    var onSocial: (SocialButton.Provider) -> Void = { _ in }

    @State private var email = ""
    @State private var password = ""
    @State private var username = ""
    @State private var revealPassword = false
    @FocusState private var focus: Field?

    private enum Field { case email, password, username }

    private var canSubmit: Bool {
        Credentials.isValidEmail(email)
            && Credentials.isValidPassword(password)
            && !username.trimmingCharacters(in: .whitespaces).isEmpty
            && !session.isWorking
    }

    var body: some View {
        AuthScaffold(topInset: DesignTokens.Layout.fieldTopInset) {
            VStack(alignment: .leading, spacing: 0) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(DesignTokens.Colors.onField)
                }
                .buttonStyle(.plain)
                .padding(.bottom, 18)

                Text("Make an account")
                    .textStyle(DesignTokens.Typography.titleLarge)
                    .foregroundStyle(DesignTokens.Colors.onField)

                Text("Takes a minute. No credit card, no newsletter.")
                    .textStyle(DesignTokens.Typography.subtitle)
                    .foregroundStyle(DesignTokens.Colors.onFieldMuted)
                    .padding(.top, 7)
            }
        } sheet: {
            HStack(spacing: DesignTokens.Spacing.lg) {
                SocialButton(provider: .apple, compact: true) { onSocial(.apple) }
                SocialButton(provider: .google, compact: true) { onSocial(.google) }
            }

            OrDivider(title: "or sign up with email")
                .padding(.vertical, 18)

            AuthField(
                label: "Email", placeholder: "you@example.com", text: $email,
                isFocused: focus == .email
            )
            .textInputAutocapitalization(.never)
            .keyboardType(.emailAddress)
            .textContentType(.emailAddress)
            .focused($focus, equals: .email)
            .padding(.bottom, DesignTokens.Spacing.xxl)

            AuthField(
                label: "Password", placeholder: "At least 8 characters", text: $password,
                isFocused: focus == .password, secure: !revealPassword
            ) {
                RevealButton(isRevealed: $revealPassword)
            }
            .textContentType(.newPassword)
            .focused($focus, equals: .password)

            PasswordStrengthMeter(strength: Credentials.strength(of: password))
                .padding(.top, 9)
                .padding(.bottom, DesignTokens.Spacing.xxl)

            AuthField(
                label: "Username", placeholder: "Whatever your friends call you", text: $username,
                isFocused: focus == .username
            )
            .textContentType(.username)
            .focused($focus, equals: .username)
            .onSubmit(submit)

            Text("Doesn't have to be unique — two Sams in one group is a problem for the two Sams.")
                .textStyle(DesignTokens.Typography.caption2)
                .foregroundStyle(DesignTokens.Colors.inkTertiary)
                .lineSpacing(2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, DesignTokens.Spacing.md)

            if let error = session.error {
                AuthErrorBanner(message: error.localizedDescription)
                    .padding(.top, DesignTokens.Spacing.xxl)
            }

            Spacer(minLength: DesignTokens.Spacing.huge)

            ButtonPrimary(session.isWorking ? "Creating…" : "Create account", action: submit)
                .disabled(!canSubmit)

            Text("By signing up you agree to the terms and the privacy policy.")
                .textStyle(DesignTokens.Typography.caption2)
                .foregroundStyle(DesignTokens.Colors.inkMuted)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .padding(.top, DesignTokens.Spacing.xxl)
        }
        .onAppear { focus = .email }
    }

    private func submit() {
        guard canSubmit else { return }
        Task { await session.register(email: email, password: password, username: username) }
    }
}

#Preview {
    RegisterView(session: Session(auth: MockAuthService()))
}
