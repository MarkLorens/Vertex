import SwiftUI

/// One proposed time on the expanded card — the label, the split, the yes count.
struct SlotSplit: Identifiable {
    let id: SlotID
    /// "Fri 12 Sep".
    let label: String
    let tally: VoteTally
    /// Ahead on the current ranking. More than one can lead — a tie is a
    /// run-off, not a winner, so nothing here picks one arbitrarily.
    let isLeading: Bool
}

/// An event still being argued over. Which of the three shapes it takes is the
/// screen's whole priority order: the one asking for your vote is expanded, the
/// one everyone has answered offers to settle it, the rest just report progress.
struct DecidingEventCard: View {

    enum Mode {
        /// Expanded — every slot's split, and the button that opens voting.
        case vote(slots: [SlotSplit], progress: String, action: String)
        /// Waiting on people. Fraction drives the bar, progress reads "2 of 5 voted".
        case waiting(fraction: Double, progress: String, detail: String)
        /// Everyone has answered. `summary` is "All 6 voted · Thu 4 Sep wins".
        case lock(summary: String, action: String)
    }

    let title: String
    let mode: Mode
    /// The "Needs you" pill. Off on `.lock`, where the green line says it better.
    var needsYou: Bool = false
    var onAction: () -> Void = {}

    private var isExpanded: Bool {
        if case .vote = mode { return true }
        return false
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: DesignTokens.Radius.cardLarge, style: .continuous)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            switch mode {
            case .vote(let slots, let progress, let action):
                header.padding(.bottom, DesignTokens.Spacing.xl)
                VStack(spacing: 7) {
                    ForEach(slots) { split in
                        row(split)
                    }
                }
                HStack {
                    Text(progress)
                        .textStyle(DesignTokens.Typography.caption3)
                        .foregroundStyle(DesignTokens.Colors.inkTertiary)
                    Spacer(minLength: DesignTokens.Spacing.lg)
                    PillAction(action, action: onAction)
                }
                .padding(.top, DesignTokens.Spacing.xxl)

            case .waiting(let fraction, let progress, let detail):
                header.padding(.bottom, DesignTokens.Spacing.lg)
                HStack(spacing: DesignTokens.Spacing.lg) {
                    ProgressTrack(
                        fraction: fraction,
                        fill: DesignTokens.Colors.accent,
                        track: DesignTokens.Colors.track
                    )
                    Text(progress)
                        .textStyle(DesignTokens.Typography.caption3)
                        .foregroundStyle(DesignTokens.Colors.inkTertiary)
                        .fixedSize()
                }
                Text(detail)
                    .textStyle(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Colors.inkSecondary)
                    .padding(.top, DesignTokens.Spacing.lg)

            case .lock(let summary, let action):
                HStack(alignment: .top, spacing: DesignTokens.Spacing.xl) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(title)
                            .textStyle(DesignTokens.Typography.rowTitle)
                            .foregroundStyle(DesignTokens.Colors.ink)
                        HStack(spacing: DesignTokens.Spacing.sm) {
                            Circle()
                                .fill(DesignTokens.Colors.positiveDot)
                                .frame(width: 6, height: 6)
                            Text(summary)
                                .textStyle(DesignTokens.Typography.captionStrong)
                                .foregroundStyle(DesignTokens.Colors.positiveInk)
                        }
                        .padding(.top, DesignTokens.Spacing.sm)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    PillAction(action, tone: .positive, action: onAction)
                }
            }
        }
        .padding(DesignTokens.Layout.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignTokens.Colors.card, in: shape)
        .overlay {
            if isExpanded {
                // 1.5pt of the field at 35% — the only card in the app that
                // outlines itself, and the only thing marking which one is next.
                shape.strokeBorder(DesignTokens.Colors.accent.opacity(0.35), lineWidth: 1.5)
            }
        }
        .shadow(DesignTokens.Elevation.card)
    }

    private var header: some View {
        HStack(spacing: DesignTokens.Spacing.lg) {
            Text(title)
                .textStyle(DesignTokens.Typography.rowTitle)
                .foregroundStyle(DesignTokens.Colors.ink)
            Spacer(minLength: 0)
            if needsYou {
                StatusPill(title: "Needs you", tone: .accent)
            }
        }
    }

    private func row(_ split: SlotSplit) -> some View {
        HStack(spacing: DesignTokens.Spacing.lg) {
            Text(split.label)
                .textStyle(DesignTokens.Typography.captionStrong)
                .foregroundStyle(split.isLeading
                    ? DesignTokens.Colors.ink
                    : DesignTokens.Colors.inkStrong)
                .lineLimit(1)
                // The doc's column is 62pt, which is exactly the width of the
                // sample it was drawn with ("Fri 12 Sep") and clips a two-digit
                // day with a wider weekday. Fixed rather than sized to content,
                // so the bars still start on one line.
                .frame(width: 74, alignment: .leading)

            VoteBar(tally: split.tally, height: 8)

            Text("\(split.tally.yes) yes")
                .textStyle(DesignTokens.Typography.caption3)
                .foregroundStyle(split.isLeading
                    ? DesignTokens.Colors.positiveInk
                    : DesignTokens.Colors.inkTertiary)
                .frame(width: 34, alignment: .trailing)
        }
    }
}

/// The action pill on a card — terracotta to move things on, green to settle.
struct PillAction: View {

    enum Tone { case accent, positive }

    private let title: String
    private let tone: Tone
    private let action: () -> Void

    init(_ title: String, tone: Tone = .accent, action: @escaping () -> Void = {}) {
        self.title = title
        self.tone = tone
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .textStyle(tone == .accent
                    ? DesignTokens.Typography.link
                    : DesignTokens.Typography.captionStrong)
                .foregroundStyle(tone == .accent
                    ? DesignTokens.Colors.onField
                    : DesignTokens.Colors.positiveInkOnTint)
                .padding(.horizontal, tone == .accent ? 18 : DesignTokens.Spacing.xxl)
                .frame(height: DesignTokens.Size.actionHeight)
                .background(tone == .accent
                    ? DesignTokens.Colors.accent
                    : DesignTokens.Colors.positiveTint, in: .capsule)
                .fixedSize()
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: DesignTokens.Spacing.lg) {
        DecidingEventCard(
            title: "Camping weekend",
            mode: .vote(
                slots: [
                    SlotSplit(id: "a", label: "Fri 12 Sep",
                              tally: VoteTally(yes: 4, no: 1, waiting: 2), isLeading: true),
                    SlotSplit(id: "b", label: "Sat 13 Sep",
                              tally: VoteTally(yes: 2, no: 2, waiting: 3), isLeading: false),
                    SlotSplit(id: "c", label: "Fri 19 Sep",
                              tally: VoteTally(yes: 1, no: 1, waiting: 5), isLeading: false),
                ],
                progress: "4 of 7 have voted",
                action: "Add your vote"
            ),
            needsYou: true
        )
        DecidingEventCard(
            title: "Board game night",
            mode: .waiting(fraction: 0.4, progress: "2 of 5 voted",
                           detail: "2 dates · closes Friday"),
            needsYou: true
        )
        DecidingEventCard(
            title: "Film club",
            mode: .lock(summary: "All 6 voted · Thu 4 Sep wins", action: "Lock it in")
        )
    }
    .padding(DesignTokens.Spacing.xxxl)
    .frame(maxHeight: .infinity, alignment: .top)
    .background(DesignTokens.Colors.sheet)
}
