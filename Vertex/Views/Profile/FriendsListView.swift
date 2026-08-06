import SwiftUI

/// 6b — the whole list, searchable, with a way to drop anyone who drifts out of
/// the group. Addresses are shown because usernames repeat by design.
struct FriendsListView: View {
    let friends: [User]
    var onBack: () -> Void = {}
    var onAddFriend: () -> Void = {}
    var onRemove: (User) -> Void = { _ in }

    @State private var search = ""
    @State private var pendingRemoval: User?

    private var results: [User] {
        let query = search.trimmingCharacters(in: .whitespaces).lowercased()
        guard !query.isEmpty else { return friends }
        return friends.filter {
            $0.username.lowercased().contains(query) || $0.emailLower.contains(query)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            nav
                .padding(.horizontal, DesignTokens.Layout.screenPadding)
                .padding(.top, DesignTokens.Spacing.sm)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text(friends.count == 1 ? "1 friend" : "\(friends.count) friends")
                    .textStyle(DesignTokens.Typography.title)
                    .foregroundStyle(DesignTokens.Colors.onField)
                Text("These are the people you can invite.")
                    .textStyle(DesignTokens.Typography.footnote)
                    .foregroundStyle(DesignTokens.Colors.onFieldMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, DesignTokens.Layout.screenPadding)
            .padding(.top, DesignTokens.Spacing.xxxl)
            .padding(.bottom, 18)

            SheetSurface(horizontalPadding: DesignTokens.Spacing.xxxl, topPadding: 18) {
                searchField
                    .padding(.bottom, DesignTokens.Spacing.xxxl)

                if friends.isEmpty {
                    empty
                } else {
                    RuledLabel(title: "All friends")
                        .padding(.horizontal, DesignTokens.Spacing.xs)
                        .padding(.bottom, DesignTokens.Spacing.sm)

                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(results.enumerated()), id: \.element.id) { index, friend in
                                row(friend)
                                if index < results.count - 1 {
                                    DesignTokens.Colors.ink.opacity(0.07)
                                        .frame(height: DesignTokens.Size.hairline)
                                        .padding(.leading, 50)
                                }
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.top, DesignTokens.Layout.fieldTopInsetLarge)
        .background(DesignTokens.Colors.field.ignoresSafeArea())
        .alert(
            "Remove \(pendingRemoval?.username ?? "")?",
            isPresented: Binding(get: { pendingRemoval != nil }, set: { if !$0 { pendingRemoval = nil } })
        ) {
            Button("Never mind", role: .cancel) { pendingRemoval = nil }
            Button("Remove", role: .destructive) {
                if let friend = pendingRemoval { onRemove(friend) }
                pendingRemoval = nil
            }
        } message: {
            // Mutual, so it's worth saying — you drop off their list too.
            Text("You'll come off each other's lists. Either of you can send a new request later.")
        }
    }

    private var nav: some View {
        ZStack {
            Text("Friends")
                .textStyle(DesignTokens.Typography.navTitle)
                .foregroundStyle(DesignTokens.Colors.onFieldStrong)
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(DesignTokens.Colors.onField)
                }
                Spacer()
                Button(action: onAddFriend) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(DesignTokens.Colors.onField)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var searchField: some View {
        HStack(spacing: 9) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(DesignTokens.Colors.inkFaint)
            TextField("Search your friends", text: $search)
                .textStyle(DesignTokens.Typography.bodyPlain)
                .foregroundStyle(DesignTokens.Colors.ink)
                .tint(DesignTokens.Colors.accent)
                .textInputAutocapitalization(.never)
        }
        .padding(.horizontal, DesignTokens.Spacing.xxl)
        .frame(height: 40)
        .background(DesignTokens.Colors.fillSubtle, in: .rect(cornerRadius: 13, style: .continuous))
    }

    private var empty: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            Image(systemName: "person.2")
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(DesignTokens.Colors.inkFaint)
            Text("No friends yet")
                .textStyle(DesignTokens.Typography.bodyLargeStrong)
                .foregroundStyle(DesignTokens.Colors.inkSecondary)
            Text("Add someone by email and they'll show up here once they accept.")
                .textStyle(DesignTokens.Typography.caption)
                .foregroundStyle(DesignTokens.Colors.inkTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    private func row(_ friend: User) -> some View {
        HStack(spacing: DesignTokens.Spacing.xl) {
            AvatarView(avatar: friend.avatar, diameter: 38)

            VStack(alignment: .leading, spacing: 1) {
                Text(friend.username)
                    .textStyle(DesignTokens.Typography.navTitle)
                    .foregroundStyle(DesignTokens.Colors.ink)
                Text(friend.email)
                    .textStyle(DesignTokens.Typography.mono(12.5))
                    .foregroundStyle(DesignTokens.Colors.inkMuted)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer(minLength: 0)

            Button {
                pendingRemoval = friend
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(DesignTokens.Colors.negativeInk)
                    .frame(width: 32, height: 32)
                    .background(DesignTokens.Colors.fillSubtle, in: .circle)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, DesignTokens.Spacing.xs)
        .padding(.vertical, 11)
    }
}

#Preview {
    FriendsListView(friends: Array(MockData.everyone.dropFirst()))
}

#Preview("Empty") {
    FriendsListView(friends: [])
}
