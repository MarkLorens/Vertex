import SwiftUI

/// 3f — round two, two options only. The first sits on cream, the second on
/// the field, so the choice reads as two halves of one screen.
struct RunoffView: View {
    @Bindable var store: EventStore
    var onBack: () -> Void = {}

    private var options: [Slot] { Array(store.detail.currentRoundSlots.prefix(2)) }

    private var closesIn: String {
        let remaining = store.event.votingClosesAt.timeIntervalSinceNow
        guard remaining > 0 else { return "closing now" }
        // Rounded, not truncated — 3h59m reading as "3h" is needlessly bleak.
        let hours = Int((remaining / 3600).rounded())
        return hours >= 1 ? "closes in \(hours)h" : "closes in \(Int((remaining / 60).rounded()))m"
    }

    var body: some View {
        VStack(spacing: 0) {
            EventNav(title: "Run-off", showsOverflow: false, onBack: onBack)
                .padding(.horizontal, DesignTokens.Layout.screenPadding)
                .padding(.top, DesignTokens.Spacing.sm)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                HStack(spacing: 7) {
                    Circle()
                        .fill(DesignTokens.Colors.onField)
                        .frame(width: 7, height: 7)
                    Text("Round \(store.event.round) · \(closesIn)".uppercased())
                        .textStyle(DesignTokens.Typography.eyebrow)
                        .foregroundStyle(DesignTokens.Colors.onFieldSecondary)
                }
                Text("Last call — pick one.")
                    .textStyle(DesignTokens.Typography.title)
                    .foregroundStyle(DesignTokens.Colors.onField)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, DesignTokens.Layout.fieldPadding)
            .padding(.top, DesignTokens.Spacing.huge)
            .padding(.bottom, DesignTokens.Spacing.sm)

            VStack(spacing: DesignTokens.Spacing.xl) {
                ForEach(Array(options.enumerated()), id: \.element.id) { index, slot in
                    RunoffCard(
                        ordinal: index == 0 ? "Option one" : "Option two",
                        slot: slot,
                        cast: store.myVote(on: slot),
                        onCream: index == 0,
                        locked: store.hasFinishedVoting
                    ) { yes in
                        store.vote(yes, on: slot)
                    }
                }

                Text("\(store.detail.finishedVotingCount) of \(store.event.participantCount) have voted in round \(store.event.round)")
                    .textStyle(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Colors.onField.opacity(0.7))
                    .padding(.top, DesignTokens.Spacing.xs)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, DesignTokens.Layout.screenPadding)
            .padding(.top, 18)
            .padding(.bottom, 34)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.top, DesignTokens.Layout.fieldTopInset)
        .background(DesignTokens.Colors.field.ignoresSafeArea())
    }
}

struct RunoffCard: View {
    let ordinal: String
    let slot: Slot
    let cast: Bool?
    /// The first card is a cream panel; the second is translucent on the field.
    let onCream: Bool
    var locked: Bool = false
    var onVote: (Bool) -> Void = { _ in }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(ordinal.uppercased())
                .textStyle(DesignTokens.Typography.eyebrow)
                .foregroundStyle(onCream
                                 ? DesignTokens.Colors.accentOnSheet
                                 : DesignTokens.Colors.onField.opacity(0.75))

            Text(SlotFormat.range(slot))
                .textStyle(DesignTokens.Typography.titleSmall)
                .foregroundStyle(onCream ? DesignTokens.Colors.ink : DesignTokens.Colors.onField)
                .padding(.top, DesignTokens.Spacing.md)

            // The doc lets these cards stretch because each carries a line of
            // commentary. Without that they hug, or they read as half-empty.
            HStack(spacing: DesignTokens.Spacing.lg) {
                VoteButton(direction: .yes, cast: cast, shape: .block, onField: !onCream) { onVote(true) }
                VoteButton(direction: .no, cast: cast, shape: .block, onField: !onCream) { onVote(false) }
            }
            .disabled(locked)
            .padding(.top, DesignTokens.Spacing.huge)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignTokens.Spacing.huge)
        .background {
            let shape = RoundedRectangle(cornerRadius: 26, style: .continuous)
            if onCream {
                shape.fill(DesignTokens.Colors.sheet)
            } else {
                shape
                    .fill(DesignTokens.Colors.onFieldSurface)
                    .overlay(shape.strokeBorder(DesignTokens.Colors.onField.opacity(0.3), lineWidth: 0.5))
            }
        }
    }
}

#Preview {
    RunoffView(store: EventStore(detail: MockData.runoffEvent, currentUserId: MockData.ivy.id))
}
