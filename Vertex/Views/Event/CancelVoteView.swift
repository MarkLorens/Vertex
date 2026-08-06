import SwiftUI

/// 3h — anyone can propose calling it off. The field desaturates so the screen
/// reads differently from every other event view without shouting.
struct CancelVoteView: View {
    @Bindable var store: EventStore

    private var cancellation: Cancellation? { store.event.cancellation }

    private var proposer: Participant? {
        cancellation.flatMap { store.detail.participant($0.proposedBy) }
    }

    private var yes: Int { cancellation?.cancelVotes ?? 0 }
    private var threshold: Int { store.event.cancelThreshold }

    private var remaining: Int { max(0, threshold - yes) }

    var body: some View {
        VStack(spacing: 0) {
            EventNav(title: store.event.name)
                .padding(.horizontal, DesignTokens.Layout.screenPadding)
                .padding(.top, DesignTokens.Spacing.sm)

            VStack(alignment: .leading, spacing: 0) {
                if let proposer {
                    HStack(spacing: DesignTokens.Spacing.md) {
                        AvatarView(avatar: proposer.avatar, diameter: 26)
                        Text("\(firstName(proposer)) wants to call it off".uppercased())
                            .textStyle(DesignTokens.Typography.eyebrow)
                            .foregroundStyle(DesignTokens.Colors.onFieldSecondary)
                    }
                    .padding(.bottom, DesignTokens.Spacing.xl)
                }

                Text("Cancel \(store.event.name.lowercased())?")
                    .textStyle(DesignTokens.Typography.title)
                    .foregroundStyle(DesignTokens.Colors.onField)

                if let cancellation, let proposer {
                    Text("\u{201C}\(cancellation.reason)\u{201D} — \(firstName(proposer)), \(cancellation.createdAt.formatted(.relative(presentation: .named)))")
                        .textStyle(DesignTokens.Typography.subtitle)
                        .foregroundStyle(DesignTokens.Colors.onFieldMuted)
                        .lineSpacing(4)
                        .padding(.top, DesignTokens.Spacing.md)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, DesignTokens.Layout.fieldPadding)
            .padding(.top, 22)
            .padding(.bottom, DesignTokens.Spacing.huge)

            SheetSurface(topPadding: 22) {
                HStack(alignment: .firstTextBaseline, spacing: DesignTokens.Spacing.lg) {
                    DesignTokens.Typography.numeral.text("\(yes)")
                        .foregroundStyle(DesignTokens.Colors.ink)
                        .monospacedDigit()
                    Text("of \(store.event.participantCount) said yes · \(threshold) needed")
                        .textStyle(DesignTokens.Typography.navTitle)
                        .foregroundStyle(DesignTokens.Colors.inkSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, DesignTokens.Spacing.xl)

                VoteBar(
                    tally: VoteTally(
                        yes: 0,
                        no: yes,
                        waiting: max(0, store.event.participantCount - yes)
                    ),
                    height: 10,
                    spacing: DesignTokens.Spacing.xs
                )
                .padding(.bottom, DesignTokens.Spacing.lg)

                Text(remaining == 0
                     ? "That's enough — it's off the calendar."
                     : "\(remaining == 1 ? "One more yes" : "\(remaining) more yeses") and it's off the calendar for everyone.")
                    .textStyle(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Colors.inkTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, DesignTokens.Spacing.huge)

                tallyCard

                Spacer(minLength: DesignTokens.Spacing.huge)

                // Both at `.large` so they keep the 54/17 geometry the doc uses;
                // sharing an HStack is what makes them half width.
                HStack(spacing: DesignTokens.Spacing.lg) {
                    ButtonPrimary("Keep it on", fill: .ink) {
                        store.voteOnCancellation(cancel: false)
                    }
                    ButtonPrimary("Cancel it", fill: .destructive) {
                        store.voteOnCancellation(cancel: true)
                    }
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.top, DesignTokens.Layout.fieldTopInset)
        .background(DesignTokens.Colors.fieldDanger.ignoresSafeArea())
    }

    private var tallyCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            RuledLabel(title: "Voted to cancel")
                .padding(.bottom, DesignTokens.Spacing.xl)
            avatarRow(store.participants(votingToCancel: true), outlined: false)
                .padding(.bottom, DesignTokens.Spacing.xxl)

            RuledLabel(title: "Still keen")
                .padding(.bottom, DesignTokens.Spacing.xl)
            HStack(spacing: DesignTokens.Spacing.md) {
                ForEach(store.participants(votingToCancel: false)) { person in
                    AvatarView(avatar: person.avatar, diameter: DesignTokens.Size.Avatar.large)
                }
                // Nobody's heard from them yet, so they're drawn as outlines.
                ForEach(store.participantsNotVotedOnCancellation()) { person in
                    Text(person.initials)
                        .textStyle(DesignTokens.Typography.avatarInitials)
                        .foregroundStyle(DesignTokens.Colors.inkFaint)
                        .frame(width: DesignTokens.Size.Avatar.large, height: DesignTokens.Size.Avatar.large)
                        .overlay {
                            Circle().strokeBorder(
                                DesignTokens.Colors.ink.opacity(0.2),
                                style: StrokeStyle(lineWidth: 1.5, dash: [3, 3])
                            )
                        }
                }
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.xxxl)
        .padding(.vertical, DesignTokens.Spacing.xxl)
        .background(DesignTokens.Colors.card, in: .rect(cornerRadius: DesignTokens.Radius.card, style: .continuous))
        .shadow(DesignTokens.Elevation.card)
    }

    private func avatarRow(_ people: [Participant], outlined: Bool) -> some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            ForEach(people) { person in
                AvatarView(avatar: person.avatar, diameter: DesignTokens.Size.Avatar.large)
            }
            Spacer(minLength: 0)
        }
    }

    private func firstName(_ participant: Participant) -> String {
        participant.username.split(separator: " ").first.map(String.init) ?? participant.username
    }
}

#Preview {
    CancelVoteView(store: EventStore(detail: MockData.cancellingEvent, currentUserId: MockData.ivy.id))
}
