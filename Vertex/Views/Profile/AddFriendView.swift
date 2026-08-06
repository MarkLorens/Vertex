import SwiftUI

/// 6c — search by email, because usernames are deliberately non-unique. Same
/// reason 4b puts the address in the accept dialogue.
struct AddFriendView: View {
    let currentUser: User
    let directory: UserDirectory
    /// Who's already a friend, so the result can say so instead of offering Add.
    var friendIds: Set<UserID> = []
    /// Previews and the design harness only — a real entry starts empty.
    var prefill: String = ""
    var onClose: () -> Void = {}

    @State private var email = ""
    @State private var result: Lookup = .idle
    @State private var sentTo: User?
    @State private var searchTask: Task<Void, Never>?
    @FocusState private var focused: Bool

    private enum Lookup: Equatable {
        case idle, searching, found(User), missing, isSelf, alreadyFriends(User), sent(User)
    }

    var body: some View {
        VStack(spacing: 0) {
            SheetHandle().padding(.bottom, DesignTokens.Spacing.md)

            HStack {
                Button("Close", action: onClose)
                    .textStyle(DesignTokens.Typography.body)
                    .foregroundStyle(DesignTokens.Colors.onFieldSecondary)
                Spacer()
                Text("Add a friend")
                    .textStyle(DesignTokens.Typography.navTitle)
                    .foregroundStyle(DesignTokens.Colors.onField)
                Spacer()
                // Balances the leading button so the title stays centred.
                Text("Close").opacity(0)
                    .textStyle(DesignTokens.Typography.body)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, DesignTokens.Layout.screenPadding)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                Text("Who are we looking for?")
                    .textStyle(DesignTokens.Typography.titleMedium)
                    .foregroundStyle(DesignTokens.Colors.onField)
                Text("Names repeat, addresses don't — so we search by email.")
                    .textStyle(DesignTokens.Typography.callout)
                    .foregroundStyle(DesignTokens.Colors.onFieldMuted)
                    .lineSpacing(3)
                    .frame(maxWidth: 310, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, DesignTokens.Layout.fieldPadding)
            .padding(.top, DesignTokens.Spacing.huge)
            .padding(.bottom, DesignTokens.Spacing.huge)

            SheetSurface(topPadding: DesignTokens.Spacing.xhuge) {
                emailField
                    .padding(.bottom, 18)

                resultArea

                OrDivider(title: "or")
                    .padding(.top, 22)
                    .padding(.bottom, DesignTokens.Spacing.xxxl)

                otherRoutes

                Spacer(minLength: DesignTokens.Spacing.huge)

                if let sentTo {
                    pendingChip(sentTo)
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.top, DesignTokens.Layout.fieldTopInset)
        .background(DesignTokens.Colors.field.ignoresSafeArea())
        .onAppear {
            focused = true
            if !prefill.isEmpty, email.isEmpty {
                email = prefill
                scheduleSearch(immediately: true)
            }
        }
    }

    private var emailField: some View {
        HStack(spacing: DesignTokens.Spacing.lg) {
            Image(systemName: "envelope")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(DesignTokens.Colors.inkFaint)
            TextField("their@email.com", text: $email)
                .textStyle(DesignTokens.Typography.bodyLarge)
                .foregroundStyle(DesignTokens.Colors.ink)
                .tint(DesignTokens.Colors.accent)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .autocorrectionDisabled()
                .focused($focused)
                .onChange(of: email) { _, _ in scheduleSearch() }
                .onSubmit { scheduleSearch(immediately: true) }
            if result == .searching {
                ProgressView().controlSize(.small)
            }
        }
        .padding(.horizontal, DesignTokens.Layout.controlPadding)
        .frame(height: 52)
        .background(DesignTokens.Colors.card, in: shape)
        .overlay {
            shape.strokeBorder(
                focused ? DesignTokens.Colors.accent : DesignTokens.Colors.border,
                lineWidth: focused ? 1.5 : 1
            )
        }
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: DesignTokens.Radius.field, style: .continuous)
    }

    @ViewBuilder
    private var resultArea: some View {
        switch result {
        case .idle, .searching:
            EmptyView()
        case .found(let user):
            resultCard(user, trailing: .add(user))
        case .alreadyFriends(let user):
            resultCard(user, trailing: .note("Already friends"))
        case .sent(let user):
            resultCard(user, trailing: .note("Requested"))
        case .isSelf:
            hint("That's you. Try someone else's address.")
        case .missing:
            hint("Nobody's using that address yet. Check the spelling, or send them the app.")
        }
    }

    private enum Trailing {
        case add(User)
        case note(String)
    }

    private func resultCard(_ user: User, trailing: Trailing) -> some View {
        HStack(spacing: 13) {
            AvatarView(avatar: user.avatar, diameter: 46)
            VStack(alignment: .leading, spacing: 2) {
                Text(user.username)
                    .textStyle(DesignTokens.Typography.rowTitle)
                    .foregroundStyle(DesignTokens.Colors.ink)
                Text(user.email)
                    .textStyle(DesignTokens.Typography.mono(13))
                    .foregroundStyle(DesignTokens.Colors.inkTertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer(minLength: 0)

            switch trailing {
            case .add(let target):
                ButtonPrimary("Add", size: .small) { send(to: target) }
            case .note(let text):
                Text(text)
                    .textStyle(DesignTokens.Typography.captionStrong)
                    .foregroundStyle(DesignTokens.Colors.inkFaint)
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.xxxl)
        .padding(.vertical, DesignTokens.Layout.controlPadding)
        .background(DesignTokens.Colors.card, in: .rect(cornerRadius: DesignTokens.Radius.card, style: .continuous))
        .shadow(DesignTokens.Elevation.card)
    }

    /// Both routes are drawn but inert — neither an invite link nor a code
    /// exists yet, and both need more than a screen (a link needs deep-link
    /// handling, a code needs something to scan it).
    private var otherRoutes: some View {
        VStack(spacing: 0) {
            routeRow("link", "Share your invite link", "Anyone with it can add you")
            DesignTokens.Colors.ink.opacity(0.07)
                .frame(height: DesignTokens.Size.hairline)
                .padding(.leading, 62)
            routeRow("qrcode", "Show your code", "For when you're stood next to them")
        }
        .background(DesignTokens.Colors.card, in: .rect(cornerRadius: DesignTokens.Radius.card, style: .continuous))
        .shadow(DesignTokens.Elevation.card)
        .opacity(0.55)
        .allowsHitTesting(false)
    }

    private func routeRow(_ symbol: String, _ title: String, _ subtitle: String) -> some View {
        HStack(spacing: DesignTokens.Spacing.xl) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(DesignTokens.Colors.accentInk)
                .frame(width: 34, height: 34)
                .background(DesignTokens.Colors.accentTint, in: .rect(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .textStyle(DesignTokens.Typography.navTitle)
                    .foregroundStyle(DesignTokens.Colors.ink)
                Text(subtitle)
                    .textStyle(DesignTokens.Typography.caption2)
                    .foregroundStyle(DesignTokens.Colors.inkTertiary)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(DesignTokens.Colors.ink.opacity(0.25))
        }
        .padding(.horizontal, DesignTokens.Spacing.xxxl)
        .padding(.vertical, DesignTokens.Layout.controlPadding)
    }

    private func hint(_ text: String) -> some View {
        Text(text)
            .textStyle(DesignTokens.Typography.caption)
            .foregroundStyle(DesignTokens.Colors.inkTertiary)
            .lineSpacing(3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, DesignTokens.Spacing.xs)
    }

    private func pendingChip(_ user: User) -> some View {
        HStack(spacing: 11) {
            AvatarView(avatar: user.avatar, diameter: 30)
            Text("Request sent to \(firstName(user)) — they'll show up here once they accept.")
                .textStyle(DesignTokens.Typography.caption)
                .foregroundStyle(DesignTokens.Colors.inkSecondary)
                .lineSpacing(2)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, DesignTokens.Layout.controlPadding)
        .padding(.vertical, 13)
        .background(DesignTokens.Colors.ink.opacity(0.045), in: .rect(cornerRadius: 16, style: .continuous))
    }

    private func firstName(_ user: User) -> String {
        user.username.split(separator: " ").first.map(String.init) ?? user.username
    }

    /// Debounced — searching on every keystroke would fire a query per letter.
    private func scheduleSearch(immediately: Bool = false) {
        searchTask?.cancel()
        let address = email.trimmingCharacters(in: .whitespaces)

        guard Credentials.isValidEmail(address) else {
            result = .idle
            return
        }
        result = .searching
        searchTask = Task {
            if !immediately {
                try? await Task.sleep(for: .milliseconds(450))
                if Task.isCancelled { return }
            }
            let found = try? await directory.findUser(email: address)
            if Task.isCancelled { return }

            guard let found else { result = .missing; return }
            if found.id == currentUser.id { result = .isSelf }
            else if friendIds.contains(found.id) { result = .alreadyFriends(found) }
            else { result = .found(found) }
        }
    }

    private func send(to user: User) {
        result = .sent(user)
        sentTo = user
        Task {
            try? await directory.sendFriendRequest(from: currentUser.id, to: user.id)
        }
    }
}

#Preview {
    AddFriendView(currentUser: MockData.ivy, directory: MockEventRepository())
}
