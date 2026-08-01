//
//  UpcomingCountdownEmpty.swift
//  Vertex
//
//  Created by Max on 01/08/26.
//

import SwiftUI

struct UpcomingCountdownEmpty: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: DesignTokens.Spacing.sm) {
                DesignTokens.Typography.countdownHero.text("00")
                DesignTokens.Typography.countdownUnit.text("d")
                    .padding(.bottom, 8)
            }
            // 32% on the colour rather than the group — a group .opacity()
            // renders offscreen for no reason here.
            .foregroundStyle(DesignTokens.Colors.onField.opacity(0.32))
            .padding(.bottom, 22)

            Text("Nothing on the books")
                .textStyle(DesignTokens.Typography.title)
                .foregroundStyle(DesignTokens.Colors.onField)
                .lineSpacing(-2)
                .padding(.bottom, 12)

            Text("All quiet here. Let's sort something out, shall we?")
                .textStyle(DesignTokens.Typography.paragraph)
                .foregroundStyle(DesignTokens.Colors.onField.opacity(0.75))
                .frame(maxWidth: 300, alignment: .leading)
        }
        .monospacedDigit()
        .frame(maxWidth: .infinity, alignment: .leading)
        // The doc lifts this block 30pt off centre; doubling it as bottom
        // padding shifts the content up by half. 1c uses 14.
        .padding(.bottom, 60)
    }
}

#Preview {
    VStack(spacing: 0) {
        Spacer(minLength: 0)
        UpcomingCountdownEmpty()
            .padding(.horizontal, DesignTokens.Layout.heroPadding)
        Spacer(minLength: 0)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DesignTokens.Colors.field)
}
