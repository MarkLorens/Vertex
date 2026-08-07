import SwiftUI

/// How far through a group is — "5 of 7 voted". Defaults to the white-on-field
/// pair; pass the sheet colours when it sits on a card instead.
struct ProgressTrack: View {
    let fraction: Double
    var fill: Color = DesignTokens.Colors.onField
    var track: Color = DesignTokens.Colors.onFieldTrack
    var height: CGFloat = DesignTokens.Size.Bar.progress

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(track)
                Capsule()
                    .fill(fill)
                    .frame(width: proxy.size.width * min(1, max(0, fraction)))
            }
        }
        .frame(height: height)
    }
}

#Preview {
    VStack(spacing: DesignTokens.Spacing.huge) {
        ProgressTrack(fraction: 0.7)
        ProgressTrack(
            fraction: 0.4,
            fill: DesignTokens.Colors.accent,
            track: DesignTokens.Colors.track
        )
    }
    .padding()
    .background(DesignTokens.Colors.field)
}
