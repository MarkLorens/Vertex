import SwiftUI

/// How a forgotten password gets reset.
///
/// The design draws 5c → 5d → 5e: ask for the address, type a six-digit code,
/// pick a new password. Firebase Auth has no such thing — `sendPasswordReset`
/// emails a **link**, and there's no API to mint or check a numeric code. Doing
/// it as designed needs a Cloud Function that generates a code, stores it with
/// an expiry, and calls the Admin SDK to change the password once it checks out.
///
/// So `.emailLink` is the default because it's the path that actually works
/// today. `.code` renders the designed screens and is ready for the moment that
/// backend exists — `AuthProviding` would grow `verifyResetCode` and
/// `setPassword` alongside it.
enum PasswordResetStyle {
    case emailLink
    case code

    var prompt: String {
        switch self {
        case .emailLink: "Give us the email you signed up with and we'll send a reset link."
        case .code: "Give us the email you signed up with and we'll send a six-digit code."
        }
    }

    var reassurance: String {
        switch self {
        case .emailLink: "If there's an account on that address, the link lands in about ten seconds. Check spam before you blame us."
        case .code: "If there's an account on that address, the code lands in about ten seconds. Check spam before you blame us."
        }
    }

    var sendTitle: String {
        switch self {
        case .emailLink: "Email me a link"
        case .code: "Send me a code"
        }
    }
}

/// 5a–5e. Everything before you're through the door.
struct AuthFlow: View {
    @Bindable var session: Session
    var resetStyle: PasswordResetStyle = .emailLink

    @State private var step: Step = .signIn
    @State private var resetEmail = ""
    @State private var unavailableProvider: SocialButton.Provider?

    private enum Step: Equatable {
        case signIn, register, forgot, code, newPassword, resetSent
    }

    var body: some View {
        ZStack {
            switch step {
            case .signIn:
                SignInView(session: session) {
                    go(.register)
                } onForgotPassword: {
                    go(.forgot)
                } onSocial: { provider in
                    unavailableProvider = provider
                }
                .transition(.opacity)

            case .register:
                RegisterView(session: session) {
                    go(.signIn)
                } onSocial: { provider in
                    unavailableProvider = provider
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))

            case .forgot:
                ForgotPasswordView(
                    session: session, style: resetStyle, email: $resetEmail,
                    onBack: { go(.signIn) },
                    onSent: { go(resetStyle == .code ? .code : .resetSent) }
                )
                .transition(.move(edge: .trailing).combined(with: .opacity))

            case .code:
                VerificationCodeView(
                    email: resetEmail,
                    onBack: { go(.forgot) },
                    onVerified: { go(.newPassword) },
                    onResend: { Task { await session.sendPasswordReset(email: resetEmail) } }
                )
                .transition(.move(edge: .trailing).combined(with: .opacity))

            case .newPassword:
                NewPasswordView(onBack: { go(.code) }, onSaved: { _ in go(.signIn) })
                    .transition(.move(edge: .trailing).combined(with: .opacity))

            case .resetSent:
                ResetSentView(email: resetEmail) { go(.signIn) }
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: step)
        .alert(
            "\(unavailableProvider?.rawValue ?? "") sign-in isn't set up",
            isPresented: Binding(get: { unavailableProvider != nil }, set: { if !$0 { unavailableProvider = nil } })
        ) {
            Button("Fine", role: .cancel) { unavailableProvider = nil }
        } message: {
            Text(unavailableProvider == .google
                 ? "Enable Google in the Firebase console, re-download GoogleService-Info.plist, and add the GoogleSignIn package."
                 : "Add the Sign in with Apple capability to the target and enable Apple in the Firebase console.")
        }
    }

    private func go(_ next: Step) {
        session.error = nil
        step = next
    }
}

/// Where `.emailLink` lands instead of 5d — the reset happens in the mail app,
/// so there's nothing to type here.
struct ResetSentView: View {
    let email: String
    var onDone: () -> Void = {}

    var body: some View {
        AuthScaffold {
            VStack(alignment: .leading, spacing: 0) {
                Text("Check your inbox")
                    .textStyle(DesignTokens.Typography.titleLarge)
                    .foregroundStyle(DesignTokens.Colors.onField)

                (Text("Sent to \(Text(email))").fontWeight(.semibold).foregroundColor(DesignTokens.Colors.onField))
                    .textStyle(DesignTokens.Typography.subtitle)
                    .foregroundStyle(DesignTokens.Colors.onFieldMuted)
                    .padding(.top, DesignTokens.Spacing.lg)
            }
        } sheet: {
            Image(systemName: "envelope.badge")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(DesignTokens.Colors.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignTokens.Spacing.xhuge)

            Text("Tap the link in that email to pick a new password. It expires in an hour.")
                .textStyle(DesignTokens.Typography.paragraph)
                .foregroundStyle(DesignTokens.Colors.inkSecondary)
                .multilineTextAlignment(.center)

            Spacer(minLength: DesignTokens.Spacing.huge)

            ButtonPrimary("Back to sign in", action: onDone)
        }
    }
}

#Preview {
    AuthFlow(session: Session(auth: MockAuthService()))
}
