import SwiftUI

/// The cream sheet that rises over the colour field. Every screen in the
/// planning flow is a band of field content above one of these.
struct SheetSurface<Content: View>: View {
    var horizontalPadding: CGFloat = DesignTokens.Layout.sheetPadding
    var topPadding: CGFloat = DesignTokens.Layout.sheetTopPadding
    /// The doc's sheets end 34pt above the bottom edge on the flow screens.
    var bottomPadding: CGFloat = 34
    /// Sheets that fill the rest of the screen versus ones that hug their
    /// content — 3e's sheet is only as tall as what's in it.
    var fills: Bool = true
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) { content }
            .frame(maxWidth: .infinity, maxHeight: fills ? .infinity : nil, alignment: .top)
            .padding(.horizontal, horizontalPadding)
            .padding(.top, topPadding)
            .padding(.bottom, bottomPadding)
            .background {
                UnevenRoundedRectangle(
                    topLeadingRadius: DesignTokens.Radius.sheet,
                    topTrailingRadius: DesignTokens.Radius.sheet
                )
                .fill(DesignTokens.Colors.sheet)
                .ignoresSafeArea(edges: .bottom)
            }
    }
}
