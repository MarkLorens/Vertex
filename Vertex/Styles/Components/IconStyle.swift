import SwiftUI

struct IconStyle: View {
    /// White at 60% over the field; 1d sets it in ink when the ground is cream.
    var color: Color = DesignTokens.Colors.onFieldSubtle

    var body: some View {
        Text("VERTEX")
            .textStyle(DesignTokens.Typography.wordmark)
            .foregroundStyle(color)
    }
}

#Preview {
    IconStyle()
        .padding()
        .background(DesignTokens.Colors.field)
}
