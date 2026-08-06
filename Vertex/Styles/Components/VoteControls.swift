import SwiftUI

/// The up/down pair. Circular on a list row (3d), a filled rectangle when the
/// card is the whole decision (3f).
struct VoteButton: View {
    enum Direction { case yes, no }
    enum Shape { case circle, block }

    let direction: Direction
    /// Nil until this person has voted — neither button is filled.
    let cast: Bool?
    var shape: Shape = .circle
    /// Over the colour field both buttons sit on translucent white instead.
    var onField: Bool = false
    var action: () -> Void = {}

    private var isChosen: Bool { cast == (direction == .yes) }

    private var fill: Color {
        guard isChosen else {
            return onField
                ? DesignTokens.Colors.onField.opacity(0.25)
                : DesignTokens.Colors.fill
        }
        return direction == .yes ? DesignTokens.Colors.positive : DesignTokens.Colors.negative
    }

    private var glyphColor: Color {
        if isChosen || onField { return DesignTokens.Colors.onField }
        return DesignTokens.Colors.inkFaint
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: direction == .yes ? "chevron.up" : "chevron.down")
                .font(.system(size: shape == .circle ? 17 : 18, weight: .heavy))
                .foregroundStyle(glyphColor)
                .frame(
                    width: shape == .circle ? DesignTokens.Size.voteButton : nil,
                    height: shape == .circle ? DesignTokens.Size.voteButton : 46
                )
                .frame(maxWidth: shape == .block ? .infinity : nil)
                .background {
                    switch shape {
                    case .circle: Circle().fill(fill)
                    case .block: RoundedRectangle(cornerRadius: DesignTokens.Radius.field, style: .continuous).fill(fill)
                    }
                }
        }
        .buttonStyle(.plain)
    }
}

/// The yes / no / not-yet split under a slot. Segments are weighted by count, so
/// an all-grey bar means nobody has voted yet.
struct VoteBar: View {
    let tally: VoteTally
    var height: CGFloat = DesignTokens.Size.Bar.vote
    var spacing: CGFloat = 2

    private struct Segment: Identifiable {
        let id = UUID()
        let count: Int
        let color: Color
    }

    private var segments: [Segment] {
        [
            Segment(count: tally.yes, color: DesignTokens.Colors.positive),
            Segment(count: tally.no, color: DesignTokens.Colors.negative),
            Segment(count: tally.waiting, color: DesignTokens.Colors.separator),
        ].filter { $0.count > 0 }
    }

    var body: some View {
        // Segments are proportional to their counts, which `maxWidth: .infinity`
        // can't express — it would split the bar evenly however the votes fell.
        GeometryReader { proxy in
            let parts = segments
            let gaps = spacing * CGFloat(max(0, parts.count - 1))
            let unit = (proxy.size.width - gaps) / CGFloat(max(1, tally.total))
            HStack(spacing: spacing) {
                ForEach(parts) { segment in
                    Capsule()
                        .fill(segment.color)
                        .frame(width: max(0, unit * CGFloat(segment.count)))
                }
            }
        }
        .frame(height: height)
    }
}

#Preview {
    VStack(spacing: DesignTokens.Spacing.huge) {
        HStack(spacing: DesignTokens.Spacing.md) {
            VoteButton(direction: .yes, cast: true)
            VoteButton(direction: .no, cast: true)
            VoteButton(direction: .yes, cast: nil)
            VoteButton(direction: .no, cast: false)
        }
        VoteBar(tally: VoteTally(yes: 4, no: 1, waiting: 2))
        VoteBar(tally: VoteTally(yes: 0, no: 0, waiting: 7))
        HStack(spacing: DesignTokens.Spacing.lg) {
            VoteButton(direction: .yes, cast: true, shape: .block)
            VoteButton(direction: .no, cast: nil, shape: .block)
        }
    }
    .padding()
    .background(DesignTokens.Colors.sheet)
}
