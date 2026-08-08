import SwiftUI

/// 5a — the way in.
struct SignInView: View {
    @Bindable var session: Session
    var onRegister: () -> Void = {}
    var onForgotPassword: () -> Void = {}
    var onSocial: (SocialButton.Provider) -> Void = { _ in }

    @State private var email = ""
    @State private var password = ""
    @State private var revealPassword = false
    @FocusState private var focus: Field?

    private enum Field { case email, password }

    private var canSubmit: Bool {
        Credentials.isValidEmail(email) && !password.isEmpty && !session.isWorking
    }

    var body: some View {
        AuthScaffold {
            VStack(alignment: .leading, spacing: 0) {
                Text("VERTEX")
                    .textStyle(DesignTokens.Typography.wordmark)
                    .foregroundStyle(DesignTokens.Colors.onFieldSubtle)

                Text("Seven people,\none date.")
                    .textStyle(DesignTokens.Typography.titleLarge)
                    .foregroundStyle(DesignTokens.Colors.onField)
                    .lineSpacing(-4)
                    .padding(.top, DesignTokens.Spacing.xxxl)

                Text("Welcome back. The group's been waiting.")
                    .textStyle(DesignTokens.Typography.subtitle)
                    .foregroundStyle(DesignTokens.Colors.onFieldMuted)
                    .padding(.top, DesignTokens.Spacing.md)
            }
        } sheet: {
            VStack(spacing: DesignTokens.Spacing.lg) {
                SocialButton(provider: .apple) { onSocial(.apple) }
                SocialButton(provider: .google) { onSocial(.google) }
            }

            OrDivider(title: "or")
                .padding(.vertical, DesignTokens.Spacing.huge)

            AuthField(
                label: "Email", placeholder: "you@example.com", text: $email,
                isFocused: focus == .email, leadingSymbol: nil
            )
            .textInputAutocapitalization(.never)
            .keyboardType(.emailAddress)
            .textContentType(.emailAddress)
            .focused($focus, equals: .email)
            .padding(.bottom, DesignTokens.Spacing.xxl)

            AuthField(
                label: "Password", placeholder: "Your password", text: $password,
                isFocused: focus == .password, secure: !revealPassword
            ) {
                RevealButton(isRevealed: $revealPassword)
            }
            .textContentType(.password)
            .focused($focus, equals: .password)
            .onSubmit(submit)

            Button(action: onForgotPassword) {
                Text("Forgotten your password?")
                    .textStyle(DesignTokens.Typography.link)
                    .foregroundStyle(DesignTokens.Colors.accentInk)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .buttonStyle(.plain)
            .padding(.top, DesignTokens.Spacing.lg)

            if let error = session.error {
                AuthErrorBanner(message: error.localizedDescription)
                    .padding(.top, DesignTokens.Spacing.xxl)
            }

            Spacer(minLength: DesignTokens.Spacing.huge)

            ButtonPrimary(session.isWorking ? "Signing in…" : "Sign in", action: submit)
                .disabled(!canSubmit)

            HStack(spacing: DesignTokens.Spacing.xs) {
                Text("New here?")
                    .textStyle(DesignTokens.Typography.footnote)
                    .foregroundStyle(DesignTokens.Colors.inkSecondary)
                Button("Make an account", action: onRegister)
                    .textStyle(DesignTokens.Typography.footnoteStrong)
                    .foregroundStyle(DesignTokens.Colors.accentInk)
                    .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, DesignTokens.Spacing.xxxl)
        }
        .onAppear { focus = .email }
    }

    private func submit() {
        guard canSubmit else { return }
        Task { await session.signIn(email: email, password: password) }
    }
}

/// Every auth screen is the same two bands: content on the field, a cream sheet
/// under it that scrolls when the keyboard eats the space.
struct AuthScaffold<Header: View, Sheet: View>: View {
    var topInset: CGFloat = DesignTokens.Layout.fieldTopInsetLarge
    @ViewBuilder let header: Header
    @ViewBuilder let sheet: Sheet

    var body: some View {
        VStack(spacing: 0) {
            header
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, DesignTokens.Layout.heroPadding)
                .padding(.bottom, DesignTokens.Layout.heroPadding)

            ScrollView {
                VStack(spacing: 0) { sheet }
                    .padding(.horizontal, DesignTokens.Layout.sheetPaddingWide)
                    .padding(.top, DesignTokens.Layout.heroPadding)
                    .padding(.bottom, 30)
                    .frame(maxWidth: .infinity, minHeight: 520, alignment: .top)
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)
            .background {
                UnevenRoundedRectangle(
                    topLeadingRadius: DesignTokens.Radius.sheet,
                    topTrailingRadius: DesignTokens.Radius.sheet
                )
                .fill(DesignTokens.Colors.sheet)
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.top, topInset)
        .background(DesignTokens.Colors.field.ignoresSafeArea())
        .dismissesKeyboardOnTap()
    }
}

struct AuthErrorBanner: View {
    let message: String

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.lg) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 14, weight: .semibold))
            Text(message)
                .textStyle(DesignTokens.Typography.caption)
            Spacer(minLength: 0)
        }
        .foregroundStyle(DesignTokens.Colors.negativeInk)
        .padding(.horizontal, DesignTokens.Spacing.xxl)
        .padding(.vertical, DesignTokens.Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignTokens.Colors.negativeTint, in: .rect(cornerRadius: DesignTokens.Radius.chip, style: .continuous))
    }
}

#Preview {
    SignInView(session: Session(auth: MockAuthService()))
}
