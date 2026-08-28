import SwiftUI

/// 3e — two slots tied. Run a second round, or the organiser just calls it.
struct DrawView: View {
    @Bindable var store: EventStore
    var onBack: () -> Void = {}

    /// Which date has been tapped. Nil until one is — the screen leads with the
    /// run-off, and picking by hand is the second way out.
    @State private var picked: SlotID?

    private var contenders: [Slot] { Array(store.detail.rankedSlots().prefix(2)) }

    /// Resolved against the live contenders, so a slot that changes underneath
    /// the selection takes the selection with it rather than settling the wrong date.
    private var pickedSlot: Slot? { contenders.first { $0.id == picked } }

    private var scoreline: String {
        contenders.map { "\(store.detail.tally(for: $0).yes)" }.joined(separator: "—")
    }

    var body: some View {
        VStack(spacing: 0) {
            // The doc draws 3e as a sheet with a grab handle, but it's presented
            // full-screen like every other event stage, so it takes their nav.
            EventNav(title: store.event.name, showsOverflow: false, onBack: onBack)
                .padding(.horizontal, DesignTokens.Layout.screenPadding)
                .padding(.top, DesignTokens.Spacing.sm)

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
                .animation(.easeInOut(duration: 0.15), value: picked)
                .padding(.bottom, 18)

                ButtonPrimary("Run a second vote") { store.startRunoff() }

                // Until a date is tapped this is the instruction for how to pick
                // one; once one is, it names what it will settle on.
                Button {
                    if let pickedSlot { store.pickManually(pickedSlot) }
                } label: {
                    Text(pickedSlot.map { "Lock in \(SlotFormat.range($0))" } ?? "Or pick one yourself")
                        .textStyle(DesignTokens.Typography.calloutStrong)
                        .foregroundStyle(pickedSlot == nil
                                         ? DesignTokens.Colors.inkTertiary
                                         : DesignTokens.Colors.accentInk)
                        .frame(maxWidth: .infinity)
                        .padding(.top, DesignTokens.Spacing.xxl)
                }
                .buttonStyle(.plain)
                .disabled(pickedSlot == nil)
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.top, DesignTokens.Layout.fieldTopInset)
        .background(DesignTokens.Colors.field.ignoresSafeArea())
    }

    private func contenderRow(_ slot: Slot) -> some View {
        let tally = store.detail.tally(for: slot)
        let backers = store.detail.activeParticipants.filter { slot.vote(by: $0.id) == true }
        let isPicked = slot.id == picked
        return Button {
            picked = isPicked ? nil : slot.id
        } label: {
            HStack(spacing: DesignTokens.Spacing.xxl) {
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
            // The 1.5pt accent stroke the notification rows use to mark "this one".
            .overlay {
                if isPicked {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(DesignTokens.Colors.accentSelected, lineWidth: 1.5)
                }
            }
            .shadow(DesignTokens.Elevation.card)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    DrawView(store: EventStore(detail: MockData.drawnEvent, currentUserId: MockData.ivy.id))
}
