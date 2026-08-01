import SwiftUI

struct StatusPill: View {

    enum Tone {
        /// Settled — a date everyone agreed on.
        case positive
        /// Waiting on you.
        case accent

        var fill: Color {
            switch self {
            case .positive: DesignTokens.Colors.positiveTint
            case .accent: DesignTokens.Colors.accentTint
            }
        }

        var ink: Color {
            switch self {
            case .positive: DesignTokens.Colors.positiveInk
            case .accent: DesignTokens.Colors.accentInk
            }
        }

        var dot: Color? {
            switch self {
            case .positive: DesignTokens.Colors.positiveDot
            case .accent: nil
            }
        }
    }

    let title: String
    var tone: Tone = .positive

    var body: some View {
        HStack(spacing: 5) {
            if let dot = tone.dot {
                Circle()
                    .fill(dot)
                    .frame(width: 6, height: 6)
            }
            Text(title)
                .textStyle(DesignTokens.Typography.caption3)
                .foregroundStyle(tone.ink)
        }
        .padding(.horizontal, 11)
        .frame(height: DesignTokens.Size.chipHeightSmall)
        .background(tone.fill, in: .capsule)
        .fixedSize()
    }
}

#Preview {
    HStack(spacing: DesignTokens.Spacing.lg) {
        StatusPill(title: "Agreed")
        StatusPill(title: "Needs you", tone: .accent)
    }
    .padding()
    .background(DesignTokens.Colors.sheet)
}
