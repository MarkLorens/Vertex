import SwiftUI

/// 3d — one yes/no per slot. Votes flip freely until this person finishes.
struct VotingView: View {
    @Bindable var store: EventStore
    var onBack: () -> Void = {}

    private var detail: EventDetail { store.detail }

    var body: some View {
        VStack(spacing: 0) {
            EventNav(title: store.event.name, onBack: onBack)
                .padding(.horizontal, DesignTokens.Layout.screenPadding)
                .padding(.top, DesignTokens.Spacing.sm)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
                Text("Which of these work?")
                    .textStyle(DesignTokens.Typography.title)
                    .foregroundStyle(DesignTokens.Colors.onField)

                HStack(spacing: DesignTokens.Spacing.lg) {
                    ProgressTrack(
                        fraction: Double(detail.finishedVotingCount) / Double(max(1, store.event.participantCount))
                    )
                    Text("\(detail.finishedVotingCount) of \(store.event.participantCount) voted")
                        .textStyle(DesignTokens.Typography.captionStrong)
                        .foregroundStyle(DesignTokens.Colors.onFieldSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, DesignTokens.Layout.fieldPadding)
            .padding(.top, DesignTokens.Spacing.huge)
            .padding(.bottom, 18)

            SheetSurface(topPadding: 22) {
                ScrollView {
                    VStack(spacing: DesignTokens.Spacing.lg) {
                        ForEach(detail.currentRoundSlots) { slot in
                            SlotVoteCard(
                                slot: slot,
                                tally: detail.tally(for: slot),
                                cast: store.myVote(on: slot),
                                locked: store.hasFinishedVoting
                            ) { yes in
                                store.vote(yes, on: slot)
                            }
                        }
                    }
                }
                .scrollIndicators(.hidden)

                Text("One vote each once you finish. Choose wisely.")
                    .textStyle(DesignTokens.Typography.caption2)
                    .foregroundStyle(DesignTokens.Colors.inkSubtle)
                    .multilineTextAlignment(.center)
                    .padding(.top, DesignTokens.Spacing.xxxl)

                Spacer(minLength: DesignTokens.Spacing.xxxl)

                if store.hasFinishedVoting {
                    Text("Your vote's in. Waiting on \(store.event.participantCount - detail.finishedVotingCount) more.")
                        .textStyle(DesignTokens.Typography.footnoteStrong)
                        .foregroundStyle(DesignTokens.Colors.inkSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: DesignTokens.Size.buttonHeight)
                } else {
                    ButtonPrimary("Finish voting", fill: .ink) { store.finishVoting() }
                        .disabled(!store.hasVotedOnEverything)
                    Text("No take-backs after this — it locks your votes in.")
                        .textStyle(DesignTokens.Typography.caption3)
                        .foregroundStyle(DesignTokens.Colors.inkSubtle)
                        .padding(.top, 9)
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.top, DesignTokens.Layout.fieldTopInset)
        .background(DesignTokens.Colors.field.ignoresSafeArea())
    }
}

/// One proposed slot with its tally, its two buttons and its split bar.
struct SlotVoteCard: View {
    let slot: Slot
    let tally: VoteTally
    let cast: Bool?
    var locked: Bool = false
    var onVote: (Bool) -> Void = { _ in }

    /// The doc dims a slot the group has clearly turned down.
    private var isLosing: Bool { tally.no > tally.yes }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: DesignTokens.Spacing.xxl) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(SlotFormat.range(slot))
                        .textStyle(DesignTokens.Typography.rowTitle)
                        .foregroundStyle(DesignTokens.Colors.ink)
                    Text(SlotFormat.tally(tally))
                        .textStyle(DesignTokens.Typography.caption)
                        .foregroundStyle(DesignTokens.Colors.inkTertiary)
                }
                Spacer(minLength: 0)

                HStack(spacing: DesignTokens.Spacing.md) {
                    VoteButton(direction: .yes, cast: cast) { onVote(true) }
                    VoteButton(direction: .no, cast: cast) { onVote(false) }
                }
                .disabled(locked)
            }

            if tally.cast > 0 {
                VoteBar(tally: tally).padding(.top, 13)
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.xxxl)
        .padding(.vertical, DesignTokens.Layout.controlPadding)
        .background(DesignTokens.Colors.card, in: .rect(cornerRadius: DesignTokens.Radius.card, style: .continuous))
        .shadow(DesignTokens.Elevation.card)
        .opacity(isLosing ? 0.75 : 1)
    }
}

/// The white-on-field progress track above the slot list.
struct ProgressTrack: View {
    let fraction: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(DesignTokens.Colors.onFieldTrack)
                Capsule()
                    .fill(DesignTokens.Colors.onField)
                    .frame(width: proxy.size.width * min(1, max(0, fraction)))
            }
        }
        .frame(height: DesignTokens.Size.Bar.progress)
    }
}

enum SlotFormat {
    /// "Fri 12 — Sun 14 Sep", collapsing to one date when the slot is a single day.
    /// Weekday is formatted apart from day+month because most locales otherwise
    /// insert a comma the design doesn't have.
    static func range(_ slot: Slot) -> String {
        if Calendar.current.isDate(slot.start, inSameDayAs: slot.end) {
            return "\(weekdayDay(slot.start)) \(slot.start.formatted(.dateTime.month(.abbreviated)))"
        }
        return "\(weekdayDay(slot.start)) — \(weekdayDay(slot.end)) \(slot.end.formatted(.dateTime.month(.abbreviated)))"
    }

    static func weekdayDay(_ date: Date) -> String {
        "\(date.formatted(.dateTime.weekday(.abbreviated))) \(date.formatted(.dateTime.day()))"
    }

    /// "4 yes · 1 no · 2 waiting", dropping the parts that are zero.
    static func tally(_ tally: VoteTally) -> String {
        var parts: [String] = []
        if tally.yes > 0 { parts.append("\(tally.yes) yes") }
        if tally.no > 0 { parts.append("\(tally.no) no") }
        if tally.waiting > 0 { parts.append("\(tally.waiting) waiting") }
        return parts.isEmpty ? "No votes yet" : parts.joined(separator: " · ")
    }
}

#Preview {
    VotingView(store: EventStore(detail: MockData.campingWeekend, currentUserId: MockData.ivy.id))
}
