import SwiftUI

/// 6a — friends belong to you, not to any one event, so this is their home.
/// The count is the way in; Add friend is the primary action on the card itself.
struct ProfileView: View {
    let user: User
    @Binding var selectedTab: Tab
    var friends: [User] = []
    var unreadNotifications: Int = 0
    var onOpenFriends: () -> Void = {}
    var onAddFriend: () -> Void = {}
    var onSignOut: () -> Void = {}

    // Not wired — placeholders until there's somewhere to keep them.
    @State private var darkMode = false
    @State private var alarms = true
    @State private var calendar = true

    var body: some View {
        Screen {
            VStack(spacing: 0) {
                header
                    .padding(.horizontal, DesignTokens.Layout.screenPadding)
                    .padding(.top, DesignTokens.Spacing.sm)

                identity
                    .padding(.horizontal, DesignTokens.Layout.screenPadding)
                    .padding(.top, DesignTokens.Spacing.huge)
                    .padding(.bottom, 22)

                sheet
            }
        }
    }

    private var header: some View {
        HStack {
            Text("Profile")
                .textStyle(DesignTokens.Typography.titleLarge)
                .foregroundStyle(DesignTokens.Colors.onField)
            Spacer()
            Image(systemName: "gearshape")
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(DesignTokens.Colors.onField)
        }
    }

    private var identity: some View {
        HStack(spacing: DesignTokens.Spacing.xxl) {
            AvatarView(avatar: user.avatar, diameter: 64)
            VStack(alignment: .leading, spacing: 2) {
                Text(user.username)
                    .textStyle(DesignTokens.Typography.titleTiny)
                    .foregroundStyle(DesignTokens.Colors.onField)
                    .lineLimit(1)
                Text(user.email)
                    .textStyle(DesignTokens.Typography.mono(14))
                    .foregroundStyle(DesignTokens.Colors.onField.opacity(0.7))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            Spacer(minLength: 0)
        }
    }

    private var sheet: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.xxl) {
                    friendsCard
                    settingsCard
                    Button("Sign out", action: onSignOut)
                        .textStyle(DesignTokens.Typography.footnoteStrong)
                        .foregroundStyle(DesignTokens.Colors.inkSubtle)
                        .buttonStyle(.plain)
                        .padding(.top, DesignTokens.Spacing.xs)
                }
                .padding(.horizontal, DesignTokens.Spacing.xxxl)
                .padding(.top, DesignTokens.Layout.sheetPadding)
                .padding(.bottom, DesignTokens.Spacing.xhuge)
            }
            .scrollIndicators(.hidden)

            TabBar(selection: $selectedTab, badges: [.notifications: unreadNotifications])
        }
        .background {
            UnevenRoundedRectangle(
                topLeadingRadius: DesignTokens.Radius.sheet,
                topTrailingRadius: DesignTokens.Radius.sheet
            )
            .fill(DesignTokens.Colors.sheet)
            .ignoresSafeArea(edges: .bottom)
        }
    }

    private var friendsCard: some View {
        Button(action: onOpenFriends) {
            VStack(spacing: DesignTokens.Spacing.xxl) {
                HStack {
                    HStack(alignment: .firstTextBaseline, spacing: DesignTokens.Spacing.md) {
                        Text("Friends")
                            .textStyle(DesignTokens.Typography.headlineTight)
                            .foregroundStyle(DesignTokens.Colors.ink)
                        Text("\(friends.count)")
                            .textStyle(DesignTokens.Typography.navTitle)
                            .foregroundStyle(DesignTokens.Colors.inkFaint)
                    }
                    Spacer(minLength: 0)
                    // Nested inside the card button, so it needs its own hit area.
                    ButtonPrimary("Add friend", icon: "plus", size: .small, action: onAddFriend)
                }

                HStack(spacing: DesignTokens.Spacing.lg) {
                    if friends.isEmpty {
                        Text("Nobody yet — add someone by email.")
                            .textStyle(DesignTokens.Typography.caption)
                            .foregroundStyle(DesignTokens.Colors.inkTertiary)
                    } else {
                        AvatarStack(
                            avatars: friends.map(\.avatar), visibleLimit: 5,
                            diameter: 34, ringColor: DesignTokens.Colors.card
                        )
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(DesignTokens.Colors.ink.opacity(0.28))
                }
            }
            .padding(DesignTokens.Spacing.xxxl)
            .background(DesignTokens.Colors.card, in: .rect(cornerRadius: 22, style: .continuous))
            .shadow(DesignTokens.Elevation.card)
        }
        .buttonStyle(.plain)
    }

    private var settingsCard: some View {
        VStack(spacing: 0) {
            settingRow("Dark mode", $darkMode)
            rule
            settingRow("Alarms & notifications", $alarms)
            rule
            settingRow("Calendar", $calendar)
        }
        .background(DesignTokens.Colors.card, in: .rect(cornerRadius: 22, style: .continuous))
        .shadow(DesignTokens.Elevation.card)
    }

    private func settingRow(_ title: String, _ binding: Binding<Bool>) -> some View {
        HStack(spacing: DesignTokens.Spacing.xl) {
            Text(title)
                .textStyle(DesignTokens.Typography.bodyPlain)
                .foregroundStyle(DesignTokens.Colors.ink)
            Spacer(minLength: 0)
            Toggle("", isOn: binding)
                .labelsHidden()
                .tint(DesignTokens.Colors.accent)
        }
        .padding(.horizontal, DesignTokens.Spacing.xxxl)
        .padding(.vertical, DesignTokens.Spacing.xl)
    }

    private var rule: some View {
        DesignTokens.Colors.ink.opacity(0.07)
            .frame(height: DesignTokens.Size.hairline)
            .padding(.leading, DesignTokens.Spacing.xxxl)
    }
}

#Preview {
    ProfileView(
        user: MockData.ivy,
        selectedTab: .constant(.profile),
        friends: Array(MockData.everyone.dropFirst()),
        unreadNotifications: 2
    )
}
