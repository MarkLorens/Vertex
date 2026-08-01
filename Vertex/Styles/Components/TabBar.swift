import SwiftUI

enum Tab: CaseIterable {
    case upcoming, yourEvents, notifications, profile

    var title: String {
        switch self {
        case .upcoming: "Upcoming"
        case .yourEvents: "Your Events"
        case .notifications: "Notifications"
        case .profile: "Profile"
        }
    }

    /// Outline symbols, matching the doc's 1.9pt stroked SVGs.
    var symbol: String {
        switch self {
        case .upcoming: "clock"
        case .yourEvents: "calendar"
        case .notifications: "bell"
        case .profile: "person"
        }
    }
}

struct TabBar: View {

    @Binding var selection: Tab
    /// Unread counts per tab; only `notifications` carries one in the doc.
    var badges: [Tab: Int] = [:]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self, content: item)
        }
        .padding(.horizontal, DesignTokens.Spacing.sm)
        .padding(.top, 9)
        .frame(height: 49, alignment: .top)
        // The doc's 83pt bar is 49pt of controls plus the home-indicator inset.
        .safeAreaPadding(.bottom)
        .background {
            DesignTokens.Colors.sheet.opacity(0.92)
                .background(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
        }
        .overlay(alignment: .top) {
            DesignTokens.Colors.ink.opacity(0.08).frame(height: 0.5)
        }
    }

    private func item(_ tab: Tab) -> some View {
        let isSelected = tab == selection
        return Button {
            selection = tab
        } label: {
            VStack(spacing: 3) {
                Image(systemName: tab.symbol)
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected
                        ? DesignTokens.Colors.accentIcon
                        : DesignTokens.Colors.inkMuted)
                    .frame(width: 26, height: 26)
                    .overlay(alignment: .topTrailing) {
                        if let count = badges[tab], count > 0 {
                            badge(count).offset(x: 9, y: -3)
                        }
                    }
                Text(tab.title)
                    // Selected is 560 and resting 500 in the doc — one step apart
                    // in a weight axis SwiftUI doesn't expose, so colour carries it.
                    .textStyle(DesignTokens.Typography.tabLabel)
                    .foregroundStyle(isSelected
                        ? DesignTokens.Colors.accentInk
                        : DesignTokens.Colors.inkSecondary)
            }
            .frame(maxWidth: .infinity)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    private func badge(_ count: Int) -> some View {
        Text("\(count)")
            .textStyle(DesignTokens.Typography.tabLabelSelected)
            .foregroundStyle(DesignTokens.Colors.onField)
            .padding(.horizontal, 4)
            .frame(minWidth: 16, minHeight: 16)
            .background(DesignTokens.Colors.badge, in: .capsule)
    }
}

#Preview {
    @Previewable @State var selection: Tab = .upcoming
    VStack(spacing: 0) {
        Spacer()
        TabBar(selection: $selection, badges: [.notifications: 2])
    }
    .background(DesignTokens.Colors.sheet)
}
