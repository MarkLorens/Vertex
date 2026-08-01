import SwiftUI

/// The terracotta colour field every screen is built on. No padding — each
/// band sets its own gutter, and the sheet and tab bar run edge to edge.
struct Screen<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            DesignTokens.Colors.field
                .ignoresSafeArea()
            content
        }
    }
}
