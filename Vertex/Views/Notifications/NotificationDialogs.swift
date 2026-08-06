import SwiftUI

/// 4b — a friend request is a decision, so it gets a real dialogue. There's no
/// profile to go and check, so the email address *is* the identity, and it's
/// the loudest line on the card.
struct FriendRequestDialog: View {
    let sender: User
    var onAccept: () -> Void = {}
    var onIgnore: () -> Void = {}
    var onDismiss: () -> Void = {}

    var body: some View {
        DialogScrim(onDismiss: onDismiss) {
            VStack(spacing: 0) {
                AvatarView(avatar: sender.avatar, diameter: 60)
                    .padding(.bottom, DesignTokens.Spacing.xxl)

                Text("Add \(sender.username)?")
                    .textStyle(DesignTokens.Typography.fieldValue)
                    .fontWeight(.bold)
                    .foregroundStyle(DesignTokens.Colors.ink)

                HStack(spacing: DesignTokens.Spacing.sm) {
                    Image(systemName: "envelope")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(DesignTokens.Colors.inkSubtle)
                    Text(sender.email)
                        .textStyle(DesignTokens.Typography.mono(13))
                        .foregroundStyle(DesignTokens.Colors.ink)
                }
                .padding(.horizontal, 11)
                .padding(.vertical, DesignTokens.Spacing.sm)
                .background(DesignTokens.Colors.fillSubtle, in: .rect(cornerRadius: 10, style: .continuous))
                .padding(.top, DesignTokens.Spacing.lg)

                Text("Check the address — it's the only way to be sure it's the \(firstName) you know. They'll be able to invite you to events.")
                    .textStyle(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Colors.inkTertiary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.top, DesignTokens.Spacing.xxl)
                    .padding(.bottom, DesignTokens.Spacing.xhuge)

                HStack(spacing: DesignTokens.Spacing.lg) {
                    DialogButton(title: "Ignore", tone: .quiet, action: onIgnore)
                    DialogButton(title: "Accept", tone: .accent, action: onAccept)
                }
            }
        }
    }

    private var firstName: String {
        sender.username.split(separator: " ").first.map(String.init) ?? sender.username
    }
}

/// 4c — declining asks once, because a mis-tap on someone else's plan isn't
/// something you can take back from this screen.
struct DeclineInviteDialog: View {
    let event: Event
    let organiser: User?
    var onDecline: () -> Void = {}
    var onDismiss: () -> Void = {}

    var body: some View {
        DialogScrim(onDismiss: onDismiss) {
            VStack(spacing: 0) {
                Text("Decline \(event.name)?")
                    .textStyle(DesignTokens.Typography.fieldValue)
                    .fontWeight(.bold)
                    .foregroundStyle(DesignTokens.Colors.ink)
                    .multilineTextAlignment(.center)

                Text("\(firstName) will see you're out. If this landed in your lap by mistake, declining is the polite fix — you can be re-invited.")
                    .textStyle(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Colors.inkTertiary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.top, DesignTokens.Spacing.xl)
                    .padding(.bottom, DesignTokens.Spacing.xhuge)

                VStack(spacing: DesignTokens.Spacing.lg) {
                    DialogButton(title: "Decline invitation", tone: .destructive, action: onDecline)
                    DialogButton(title: "Never mind", tone: .quiet, action: onDismiss)
                }
            }
        }
    }

    private var firstName: String {
        guard let organiser else { return "They" }
        return organiser.username.split(separator: " ").first.map(String.init) ?? organiser.username
    }
}

// MARK: - Shared chrome

/// A dimmed backdrop with a centred card. Tapping outside dismisses, which is
/// safe here because neither dialogue's default is destructive.
struct DialogScrim<Content: View>: View {
    var onDismiss: () -> Void = {}
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)

            content
                .padding(DesignTokens.Spacing.xhuge)
                .frame(maxWidth: .infinity)
                .background(DesignTokens.Colors.sheet, in: .rect(cornerRadius: 28, style: .continuous))
                .padding(.horizontal, DesignTokens.Spacing.xhuge)
                .shadow(color: .black.opacity(0.3), radius: 30, x: 0, y: 24)
        }
        .transition(.opacity)
    }
}

struct DialogButton: View {
    enum Tone { case accent, quiet, destructive }

    let title: String
    var tone: Tone = .quiet
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Text(title)
                .textStyle(DesignTokens.Typography.button)
                .foregroundStyle(label)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(background, in: .rect(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var background: Color {
        switch tone {
        case .accent: DesignTokens.Colors.accent
        case .quiet: DesignTokens.Colors.fill
        case .destructive: DesignTokens.Colors.negativeTint
        }
    }

    private var label: Color {
        switch tone {
        case .accent: DesignTokens.Colors.onField
        case .quiet: DesignTokens.Colors.inkSecondary
        case .destructive: DesignTokens.Colors.negativeInk
        }
    }
}

#Preview("4b Friend request") {
    ZStack {
        DesignTokens.Colors.field.ignoresSafeArea()
        FriendRequestDialog(sender: MockData.mara)
    }
}

#Preview("4c Decline") {
    ZStack {
        DesignTokens.Colors.field.ignoresSafeArea()
        DeclineInviteDialog(event: MockData.campingWeekend.event, organiser: MockData.theo)
    }
}
