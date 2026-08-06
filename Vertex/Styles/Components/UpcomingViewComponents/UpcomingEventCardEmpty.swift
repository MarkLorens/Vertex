//
//  UpcomingEventCardEmpty.swift
//  Vertex
//
//  Created by Max on 01/08/26.
//

import SwiftUI

struct UpcomingEventCardEmpty: View {
    var onStartPlanning: () -> Void = {}

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xxl) {
            ButtonPrimary("Start Planning", icon: "plus", action: onStartPlanning)

            Text("Or check if there's anything going down in Your Events")
                .textStyle(DesignTokens.Typography.footnoteSmall)
                .foregroundStyle(DesignTokens.Colors.inkSecondary)
                .multilineTextAlignment(.center)
        }
    }
}

#Preview {
    UpcomingEventCardEmpty()
        .padding(.horizontal, DesignTokens.Layout.sheetPaddingWide)
        .padding(.vertical, DesignTokens.Layout.sheetPadding)
        .background(DesignTokens.Colors.sheet)
}
