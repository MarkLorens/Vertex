import SwiftUI

/// 3e — two slots tied. Run a second round, or the organiser just calls it.
struct DrawView: View {
    @Bindable var store: EventStore

    private var contenders: [Slot] { Array(store.detail.rankedSlots().prefix(2)) }

    private var scoreline: String {
        contenders.map { "\(store.detail.tally(for: $0).yes)" }.joined(separator: "—")
    }

    var body: some View {
        VStack(spacing: 0) {
            SheetHandle().padding(.bottom, DesignTokens.Spacing.sm)

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 0) {
                DesignTokens.Typography.countdownLarge.text(scoreline)
                    .foregroundStyle(DesignTokens.Colors.onField)

                Text("Dead heat.")
                    .textStyle(DesignTokens.Typography.title)
                    .foregroundStyle(DesignTokens.Colors.onField)
                    .padding(.top, DesignTokens.Spacing.xxxl)

                Text("Two dates tied. One more round, just those two — five minutes and it's settled.")
                    .textStyle(DesignTokens.Typography.paragraph)
                    .foregroundStyle(DesignTokens.Colors.onField.opacity(0.75))
                    .frame(maxWidth: 310, alignment: .leading)
                    .padding(.top, DesignTokens.Spacing.lg)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, DesignTokens.Layout.heroPadding)
            .padding(.bottom, 40)

            Spacer(minLength: 0)

            SheetSurface(fills: false) {
                VStack(spacing: DesignTokens.Spacing.lg) {
                    ForEach(contenders) { slot in
                        contenderRow(slot)
                    }
                }
                .padding(.bottom, 18)

                ButtonPrimary("Run a second vote") { store.startRunoff() }

                Button {
                    if let first = contenders.first { store.pickManually(first) }
                } label: {
                    Text("Or pick one yourself")
                        .textStyle(DesignTokens.Typography.calloutStrong)
                        .foregroundStyle(DesignTokens.Colors.inkTertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.top, DesignTokens.Spacing.xxl)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.top, DesignTokens.Layout.fieldTopInset)
        .background(DesignTokens.Colors.field.ignoresSafeArea())
    }

    private func contenderRow(_ slot: Slot) -> some View {
        let tally = store.detail.tally(for: slot)
        let backers = store.detail.activeParticipants.filter { slot.vote(by: $0.id) == true }
        return HStack(spacing: DesignTokens.Spacing.xxl) {
            VStack(alignment: .leading, spacing: 2) {
                Text(SlotFormat.range(slot))
                    .textStyle(DesignTokens.Typography.bodyLargeStrong)
                    .foregroundStyle(DesignTokens.Colors.ink)
                Text(SlotFormat.tally(tally))
                    .textStyle(DesignTokens.Typography.caption2)
                    .foregroundStyle(DesignTokens.Colors.inkTertiary)
            }
            Spacer(minLength: 0)
            AvatarStack(
                avatars: backers.map(\.avatar),
                visibleLimit: 3,
                diameter: DesignTokens.Size.Avatar.medium,
                ringColor: DesignTokens.Colors.card
            )
        }
        .padding(.horizontal, DesignTokens.Spacing.xxxl)
        .padding(.vertical, DesignTokens.Spacing.xxl)
        .background(DesignTokens.Colors.card, in: .rect(cornerRadius: 18, style: .continuous))
        .shadow(DesignTokens.Elevation.card)
    }
}

#Preview {
    DrawView(store: EventStore(detail: MockData.drawnEvent, currentUserId: MockData.ivy.id))
}
