import SwiftUI

/// 4a, and 4d when there's nothing. Two kinds only: a friend request is a
/// decision, so the row taps through to a proper dialogue; an invitation is a
/// nudge, so the buttons sit in the row.
struct NotificationsView: View {
    let model: NotificationsModel
    @Binding var selectedTab: Tab
    var onPlan: () -> Void = {}
    var onRespondToRequest: (FriendRequest, User) -> Void = { _, _ in }
    var onJoin: (Event) -> Void = { _ in }
    var onDecline: (Event, User?) -> Void = { _, _ in }
    var onOpenEvent: (Event) -> Void = { _ in }

    private var isEmpty: Bool { model.items.isEmpty }

    var body: some View {
        Screen {
            VStack(spacing: 0) {
                header
                    .padding(.horizontal, DesignTokens.Layout.screenPadding)
                    .padding(.top, DesignTokens.Spacing.sm)

                Text(subtitle)
                    .textStyle(DesignTokens.Typography.footnote)
                    .foregroundStyle(DesignTokens.Colors.onFieldMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, DesignTokens.Layout.screenPadding)
                    .padding(.top, DesignTokens.Spacing.xs)

                sheet.padding(.top, 18)
            }
        }
    }

    private var subtitle: String {
        let count = model.badgeCount
        if isEmpty { return "Nothing waiting on you." }
        return count == 0 ? "All caught up" : "\(count) new · nothing on fire"
    }

    private var header: some View {
        HStack {
            Text("Notifications")
                .textStyle(DesignTokens.Typography.titleLarge)
                .foregroundStyle(DesignTokens.Colors.onField)
            Spacer(minLength: DesignTokens.Spacing.xl)
            ButtonSecondary("Plan", icon: "plus", action: onPlan)
        }
    }

    private var sheet: some View {
        VStack(spacing: 0) {
            if isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        section("New", model.actionable)
                        section("Earlier", model.earlier)
                    }
                    .padding(.horizontal, DesignTokens.Spacing.xxxl)
                    .padding(.top, DesignTokens.Layout.sheetPadding)
                    .padding(.bottom, DesignTokens.Spacing.xhuge)
                }
                .scrollIndicators(.hidden)
            }

            TabBar(selection: $selectedTab, badges: [.notifications: model.badgeCount])
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

    @ViewBuilder
    private func section(_ title: String, _ items: [NotificationItem]) -> some View {
        if !items.isEmpty {
            RuledLabel(title: title)
                .padding(.horizontal, DesignTokens.Spacing.xs)
                .padding(.bottom, DesignTokens.Spacing.xl)

            VStack(spacing: DesignTokens.Spacing.lg) {
                ForEach(items) { item in
                    NotificationRow(
                        item: item,
                        onRespondToRequest: onRespondToRequest,
                        onJoin: onJoin,
                        onDecline: onDecline,
                        onOpenEvent: onOpenEvent
                    )
                }
            }
            .padding(.bottom, DesignTokens.Spacing.xhuge)
        }
    }

    /// 4d.
    private var emptyState: some View {
        VStack(spacing: 0) {
            Spacer()
            Image(systemName: "bell")
                .font(.system(size: 30, weight: .light))
                .foregroundStyle(DesignTokens.Colors.ink.opacity(0.3))
                .frame(width: 78, height: 78)
                .background(DesignTokens.Colors.fillSubtle, in: .circle)
                .padding(.bottom, DesignTokens.Spacing.huge)

            Text("All quiet")
                .textStyle(DesignTokens.Typography.headlineTight)
                .foregroundStyle(DesignTokens.Colors.ink)
                .padding(.bottom, DesignTokens.Spacing.md)

            Text("Friend requests and invitations land here. Nobody wants anything from you right now.")
                .textStyle(DesignTokens.Typography.subtitle)
                .foregroundStyle(DesignTokens.Colors.inkSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity)
    }
}

struct NotificationRow: View {
    let item: NotificationItem
    var onRespondToRequest: (FriendRequest, User) -> Void = { _, _ in }
    var onJoin: (Event) -> Void = { _ in }
    var onDecline: (Event, User?) -> Void = { _, _ in }
    var onOpenEvent: (Event) -> Void = { _ in }

    var body: some View {
        switch item {
        case .friendRequest(let request, let sender):
            friendRequestRow(request, sender)
        case .friendAccepted(let request, let friend):
            settledRow(avatar: friend.avatar) {
                Text("\(strong(friend.username)) is now your friend")
                    .textStyle(DesignTokens.Typography.subtitle)
                    .foregroundStyle(DesignTokens.Colors.inkStrong)
                Text(relative(request.respondedAt ?? request.createdAt))
                    .textStyle(DesignTokens.Typography.caption2)
                    .foregroundStyle(DesignTokens.Colors.inkSubtle)
                    .padding(.top, 2)
            }
        case .eventInvite(let event, let organiser, let status):
            if status == .invited {
                inviteRow(event, organiser)
            } else {
                joinedRow(event, organiser)
            }
        }
    }

    // MARK: New

    private func friendRequestRow(_ request: FriendRequest, _ sender: User) -> some View {
        Button {
            onRespondToRequest(request, sender)
        } label: {
            HStack(spacing: 13) {
                AvatarView(avatar: sender.avatar, diameter: 42)
                    .overlay(alignment: .bottomTrailing) {
                        Image(systemName: "plus")
                            .font(.system(size: 8, weight: .black))
                            .foregroundStyle(DesignTokens.Colors.onField)
                            .frame(width: 19, height: 19)
                            .background(DesignTokens.Colors.accent, in: .circle)
                            .overlay(Circle().strokeBorder(DesignTokens.Colors.card, lineWidth: 2))
                            .offset(x: 2, y: 2)
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(strong(sender.username)) wants to be friends")
                        .textStyle(DesignTokens.Typography.subtitle)
                        .foregroundStyle(DesignTokens.Colors.ink)
                        .multilineTextAlignment(.leading)
                    Text(relative(request.createdAt))
                        .textStyle(DesignTokens.Typography.caption2)
                        .foregroundStyle(DesignTokens.Colors.inkTertiary)
                }
                Spacer(minLength: 0)

                Text("Respond")
                    .textStyle(DesignTokens.Typography.captionStrong)
                    .foregroundStyle(DesignTokens.Colors.onField)
                    .padding(.horizontal, DesignTokens.Spacing.xxl)
                    .frame(height: 32)
                    .background(DesignTokens.Colors.accent, in: .capsule)
            }
            .padding(DesignTokens.Spacing.xxl)
            .background(DesignTokens.Colors.card, in: shape)
            .overlay(shape.strokeBorder(DesignTokens.Colors.accentSelected, lineWidth: 1.5))
            .shadow(DesignTokens.Elevation.card)
        }
        .buttonStyle(.plain)
    }

    private func inviteRow(_ event: Event, _ organiser: User?) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(alignment: .top, spacing: 13) {
                AvatarView(avatar: organiser?.avatar ?? unknownAvatar, diameter: 42)
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(strong(firstName(organiser))) is planning \(strong(event.name)). Hop on in!")
                        .textStyle(DesignTokens.Typography.subtitle)
                        .foregroundStyle(DesignTokens.Colors.ink)
                        .multilineTextAlignment(.leading)
                    Text("\(relative(event.createdAt)) · \(event.participantCount) invited")
                        .textStyle(DesignTokens.Typography.caption2)
                        .foregroundStyle(DesignTokens.Colors.inkTertiary)
                }
                Spacer(minLength: 0)
            }

            HStack(spacing: DesignTokens.Spacing.md) {
                ButtonPrimary("I'm in", size: .medium) { onJoin(event) }
                Button {
                    onDecline(event, organiser)
                } label: {
                    Text("Decline")
                        .textStyle(DesignTokens.Typography.footnoteStrong)
                        .foregroundStyle(DesignTokens.Colors.inkSecondary)
                        .padding(.horizontal, 18)
                        .frame(height: 38)
                        .background(DesignTokens.Colors.fill, in: .rect(cornerRadius: DesignTokens.Radius.chip, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(.leading, 55)
        }
        .padding(DesignTokens.Spacing.xxl)
        .background(DesignTokens.Colors.card, in: shape)
        .overlay(shape.strokeBorder(DesignTokens.Colors.accentSelected, lineWidth: 1.5))
        .shadow(DesignTokens.Elevation.card)
    }

    // MARK: Earlier

    private func joinedRow(_ event: Event, _ organiser: User?) -> some View {
        Button {
            onOpenEvent(event)
        } label: {
            settledRow(avatar: organiser?.avatar ?? unknownAvatar) {
                Text("\(strong(firstName(organiser))) is planning \(strong(event.name)).")
                    .textStyle(DesignTokens.Typography.subtitle)
                    .foregroundStyle(DesignTokens.Colors.inkStrong)
                    .multilineTextAlignment(.leading)

                HStack(spacing: 5) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(DesignTokens.Colors.positiveDot)
                    Text(event.isSettled ? "You're in — date settled" : "You're in — dates to vote on")
                        .textStyle(DesignTokens.Typography.caption2)
                        .foregroundStyle(DesignTokens.Colors.positiveInk)
                }
                .padding(.top, DesignTokens.Spacing.xs)
            }
        }
        .buttonStyle(.plain)
    }

    /// The resolved rows sit on translucent white rather than a card — they've
    /// been dealt with, so they recede.
    private func settledRow<Content: View>(
        avatar: Avatar, @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(spacing: 13) {
            AvatarView(avatar: avatar, diameter: 42)
            VStack(alignment: .leading, spacing: 0) { content() }
            Spacer(minLength: 0)
        }
        .padding(DesignTokens.Spacing.xxl)
        .background(DesignTokens.Colors.card.opacity(0.65), in: shape)
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: DesignTokens.Radius.card, style: .continuous)
    }

    private var unknownAvatar: Avatar { Avatar(initials: "?", colorIndex: 0) }

    /// A name or title picked out of the sentence around it. The colour rides on
    /// the run rather than the row, because the settled rows set their body one
    /// step down from full ink and the name still wants all of it.
    private func strong(_ value: String) -> Text {
        Text(value)
            .fontWeight(.bold)
            .foregroundColor(DesignTokens.Colors.ink)
    }

    private func firstName(_ user: User?) -> String {
        guard let user else { return "Someone" }
        return user.username.split(separator: " ").first.map(String.init) ?? user.username
    }

    private func relative(_ date: Date) -> String {
        date.formatted(.relative(presentation: .named)).localizedCapitalized
    }
}

#Preview("Empty") {
    NotificationsView(
        model: NotificationsModel(
            directory: MockEventRepository(),
            events: EventListModel(repository: MockEventRepository(), uid: MockData.ivy.id),
            uid: MockData.ivy.id
        ),
        selectedTab: .constant(.notifications)
    )
}
