import SwiftUI

/// 3c — tap the days that work. Consecutive taps collapse into ranges, which
/// become the slots everyone votes on.
struct AvailabilityView: View {
    @Bindable var draft: EventDraft
    var isSending = false
    var onBack: () -> Void = {}
    var onSend: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            SheetHandle().padding(.bottom, DesignTokens.Spacing.md)

            StepNav(
                leading: "Back", trailing: "Send", step: 2, stepCount: 3,
                trailingEnabled: draft.canSend,
                onLeading: onBack, onTrailing: onSend
            )
            .padding(.horizontal, DesignTokens.Layout.screenPadding)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text("When could you do it?")
                    .textStyle(DesignTokens.Typography.title)
                    .foregroundStyle(DesignTokens.Colors.onField)
                Text("Tap the days and time that work for you.")
                    .textStyle(DesignTokens.Typography.callout)
                    .foregroundStyle(DesignTokens.Colors.onFieldMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, DesignTokens.Layout.fieldPadding)
            .padding(.top, 22)
            .padding(.bottom, 18)

            SheetSurface(topPadding: DesignTokens.Layout.sheetPadding) {
                AvailabilityPicker(draft: draft)

                Spacer(minLength: DesignTokens.Spacing.huge)

                ButtonPrimary(isSending ? "Sending…" : "Send to the group", action: onSend)
                    .disabled(!draft.canSend || isSending)
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.top, DesignTokens.Layout.fieldTopInset)
        .background(DesignTokens.Colors.field.ignoresSafeArea())
    }
}

#Preview {
    AvailabilityView(draft: {
        let d = EventDraft(organiserId: MockData.ivy.id)
        let calendar = Calendar.current
        for offset in [11, 12, 18] {
            if let day = calendar.date(byAdding: .day, value: offset, to: .now) {
                d.toggleDay(day)
            }
        }
        return d
    }())
}
