import SwiftUI

/// 3b — pick who's coming. "Share a link instead" is deliberately not here yet.
struct InviteFriendsView: View {
    @Bindable var draft: EventDraft
    var friends: [User] = []
    /// Per-friend notes aren't stored yet, so rows fall back to the address —
    /// which is the only way to tell two people with the same name apart.
    var notes: [FriendNote] = []
    var onBack: () -> Void = {}
    var onNext: () -> Void = {}

    @State private var search = ""

    private var invited: [User] { friends.filter { draft.invitedIds.contains($0.id) } }

    private var results: [User] {
        let query = search.trimmingCharacters(in: .whitespaces).lowercased()
        guard !query.isEmpty else { return friends }
        return friends.filter {
            $0.username.lowercased().contains(query) || $0.emailLower.contains(query)
        }
    }

    private func note(for user: User) -> String? {
        notes.first { $0.id == user.id }?.note ?? user.email
    }

    var body: some View {
        VStack(spacing: 0) {
            SheetHandle().padding(.bottom, DesignTokens.Spacing.md)

            StepNav(
                leading: "Back", trailing: "Next", step: 1, stepCount: 3,
                trailingEnabled: draft.canLeaveInvites,
                onLeading: onBack, onTrailing: onNext
            )
            .padding(.horizontal, DesignTokens.Layout.screenPadding)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text("Who's in?")
                    .textStyle(DesignTokens.Typography.title)
                    .foregroundStyle(DesignTokens.Colors.onField)
                Text("\(invited.count) invited · everyone can add more later.")
                    .textStyle(DesignTokens.Typography.callout)
                    .foregroundStyle(DesignTokens.Colors.onFieldMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, DesignTokens.Layout.fieldPadding)
            .padding(.top, 22)
            .padding(.bottom, DesignTokens.Spacing.xxxl)

            if !invited.isEmpty {
                FlowRow(spacing: 7, lineSpacing: 7) {
                    ForEach(invited) { user in
                        invitedPill(user)
                    }
                }
                .padding(.horizontal, DesignTokens.Layout.screenPadding)
                .padding(.bottom, 18)
            }

            SheetSurface(topPadding: DesignTokens.Layout.sheetPadding) {
                searchField
                    .padding(.bottom, DesignTokens.Spacing.md)

                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(results.enumerated()), id: \.element.id) { index, user in
                            friendRow(user)
                            if index < results.count - 1 {
                                DesignTokens.Colors.ink.opacity(0.07)
                                    .frame(height: DesignTokens.Size.hairline)
                                    .padding(.leading, 50)
                            }
                        }
                    }
                }
                .scrollIndicators(.hidden)

                ButtonPrimary("Next · Your availability", icon: "chevron.right", iconEdge: .trailing, action: onNext)
                    .disabled(!draft.canLeaveInvites)
                    .padding(.top, DesignTokens.Spacing.xxl)
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.top, DesignTokens.Layout.fieldTopInset)
        .background(DesignTokens.Colors.field.ignoresSafeArea())
        .dismissesKeyboardOnTap()
    }

    private func invitedPill(_ user: User) -> some View {
        Button {
            draft.toggleInvite(user.id)
        } label: {
            HStack(spacing: 7) {
                AvatarView(avatar: user.avatar, diameter: 22)
                Text(user.username.split(separator: " ").first.map(String.init) ?? user.username)
                    .textStyle(DesignTokens.Typography.captionStrong)
                    .foregroundStyle(DesignTokens.Colors.onField)
            }
            .padding(.leading, 5)
            .padding(.trailing, DesignTokens.Spacing.xl)
            .padding(.vertical, 5)
            .background(DesignTokens.Colors.onFieldSurface, in: .capsule)
        }
        .buttonStyle(.plain)
    }

    private var searchField: some View {
        HStack(spacing: 9) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(DesignTokens.Colors.inkFaint)
            TextField("Search friends", text: $search)
                .textStyle(DesignTokens.Typography.bodyPlain)
                .foregroundStyle(DesignTokens.Colors.ink)
                .tint(DesignTokens.Colors.accent)
        }
        .padding(.horizontal, DesignTokens.Spacing.xxl)
        .frame(height: 40)
        .background(DesignTokens.Colors.fillSubtle, in: .rect(cornerRadius: 13, style: .continuous))
    }

    private func friendRow(_ user: User) -> some View {
        let isInvited = draft.invitedIds.contains(user.id)
        return Button {
            draft.toggleInvite(user.id)
        } label: {
            HStack(spacing: DesignTokens.Spacing.xl) {
                AvatarView(avatar: user.avatar, diameter: 38)

                VStack(alignment: .leading, spacing: 1) {
                    Text(user.username)
                        .textStyle(DesignTokens.Typography.bodyLargeStrong)
                        .foregroundStyle(DesignTokens.Colors.ink)
                    if let note = note(for: user) {
                        Text(note)
                            .textStyle(DesignTokens.Typography.caption)
                            .foregroundStyle(DesignTokens.Colors.inkTertiary)
                    }
                }
                Spacer(minLength: 0)

                Group {
                    if isInvited {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .heavy))
                            .foregroundStyle(DesignTokens.Colors.onField)
                            .frame(width: 26, height: 26)
                            .background(DesignTokens.Colors.accent, in: .circle)
                    } else {
                        Circle()
                            .strokeBorder(DesignTokens.Colors.ink.opacity(0.18), lineWidth: 1.5)
                            .frame(width: 26, height: 26)
                    }
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.xs)
            .padding(.vertical, 11)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    InviteFriendsView(draft: {
        let d = EventDraft(organiserId: MockData.ivy.id)
        d.name = "Camping weekend"
        d.invitedIds = [MockData.sam.id, MockData.jo.id, MockData.theo.id, MockData.ada.id]
        return d
    }())
}
