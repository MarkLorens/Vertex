import SwiftUI

enum EventSegment: CaseIterable {
    case decided, deciding

    var title: String {
        switch self {
        case .decided: "Decided"
        case .deciding: "Deciding"
        }
    }
}

/// Decided | Deciding, sitting on the colour field above the sheet. The count
/// rides in the segment rather than in a subtitle, so only one list shows at a
/// time without hiding how much is on the other side.
struct EventSegmentedControl: View {

    @Binding var selection: EventSegment
    var counts: [EventSegment: Int] = [:]

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            ForEach(EventSegment.allCases, id: \.self, content: segment)
        }
        .padding(DesignTokens.Spacing.xs)
        .background(
            DesignTokens.Colors.onFieldSurfaceStrong,
            in: .rect(cornerRadius: DesignTokens.Radius.field, style: .continuous)
        )
    }

    private func segment(_ segment: EventSegment) -> some View {
        let isSelected = segment == selection
        return Button {
            selection = segment
        } label: {
            HStack(spacing: DesignTokens.Spacing.sm) {
                Text(segment.title)
                    .textStyle(DesignTokens.Typography.footnoteStrong)
                    // Selected is 680 and resting 600 in the doc — one step apart
                    // in a weight axis SwiftUI doesn't expose, so colour carries it.
                    .foregroundStyle(isSelected
                        ? DesignTokens.Palette.terracottaShade
                        : DesignTokens.Colors.onFieldSecondary)
                count(counts[segment] ?? 0, isSelected: isSelected)
            }
            .frame(maxWidth: .infinity)
            .frame(height: DesignTokens.Size.pillHeight)
            .background {
                if isSelected {
                    // 11pt, not a scale value: the trough's 14pt radius less its 4pt inset.
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(DesignTokens.Colors.card)
                        .shadow(DesignTokens.Elevation.segment)
                }
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func count(_ value: Int, isSelected: Bool) -> some View {
        if isSelected {
            Text("\(value)")
                .textStyle(DesignTokens.Typography.countBadge)
                .foregroundStyle(DesignTokens.Colors.onField)
                .padding(.horizontal, 5)
                .frame(minWidth: 18, minHeight: 18)
                .background(DesignTokens.Colors.accent, in: .capsule)
        } else {
            Text("\(value)")
                .textStyle(DesignTokens.Typography.caption3)
                .foregroundStyle(DesignTokens.Colors.onFieldSubtle)
        }
    }
}

#Preview {
    @Previewable @State var selection: EventSegment = .deciding
    EventSegmentedControl(selection: $selection, counts: [.decided: 3, .deciding: 3])
        .padding(.horizontal, DesignTokens.Layout.screenPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignTokens.Colors.field)
}
