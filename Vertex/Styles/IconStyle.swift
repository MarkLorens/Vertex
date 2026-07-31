//
//  Icon.swift
//  Vertex
//
//  Created by Max on 31/07/26.
//

import SwiftUI

struct IconStyle: View {
    var body: some View {
        Text("VERTEX")
            .foregroundStyle(DesignTokens.Colors.inkSubtle)
            .textStyle(DesignTokens.Typography.wordmark)
    }
}

#Preview {
    IconStyle()
}
