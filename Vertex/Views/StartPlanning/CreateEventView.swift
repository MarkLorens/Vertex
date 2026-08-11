import SwiftUI

/// 3a — name it and say roughly where. When it runs is the group's to vote on,
/// and how long it lasts isn't Vertex's business.
struct CreateEventView: View {
    @Bindable var draft: EventDraft
    var onCancel: () -> Void = {}
    var onNext: () -> Void = {}

    @FocusState private var focus: Field?
    private enum Field { case name, place }

    var body: some View {
        VStack(spacing: 0) {
            SheetHandle().padding(.bottom, DesignTokens.Spacing.md)

            StepNav(
                leading: "Cancel", trailing: "Next", step: 0, stepCount: 3,
                trailingEnabled: draft.canLeaveDetails,
                onLeading: onCancel, onTrailing: onNext
            )
            .padding(.horizontal, DesignTokens.Layout.screenPadding)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text("What's the plan?")
                    .textStyle(DesignTokens.Typography.title)
                    .foregroundStyle(DesignTokens.Colors.onField)
                Text("Cooking, hiking, or maybe a game night?")
                    .textStyle(DesignTokens.Typography.callout)
                    .foregroundStyle(DesignTokens.Colors.onFieldMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, DesignTokens.Layout.fieldPadding)
            .padding(.top, 22)
            .padding(.bottom, DesignTokens.Spacing.huge)

            SheetSurface {
                Text("What are we up to?")
                    .textStyle(DesignTokens.Typography.eyebrow)
                    .foregroundStyle(DesignTokens.Colors.inkSubtle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, DesignTokens.Spacing.md)

                TextField("Camping weekend", text: $draft.name)
                    .textStyle(DesignTokens.Typography.titleSmall)
                    .foregroundStyle(DesignTokens.Colors.ink)
                    .tint(DesignTokens.Colors.accent)
                    .focused($focus, equals: .name)
                    .padding(.bottom, DesignTokens.Spacing.xl)
                    .overlay(alignment: .bottom) {
                        DesignTokens.Colors.accent.frame(height: 1.5)
                    }

                Text("Where is it?")
                    .textStyle(DesignTokens.Typography.eyebrow)
                    .foregroundStyle(DesignTokens.Colors.inkSubtle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 26)
                    .padding(.bottom, DesignTokens.Spacing.md)

                HStack(spacing: 9) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(DesignTokens.Colors.ink.opacity(0.3))
                    TextField("Somewhere in the Peaks", text: $draft.place)
                        .textStyle(DesignTokens.Typography.fieldValue)
                        .foregroundStyle(DesignTokens.Colors.ink)
                        .tint(DesignTokens.Colors.accent)
                        .focused($focus, equals: .place)
                }
                .padding(.bottom, DesignTokens.Spacing.xl)
                .overlay(alignment: .bottom) {
                    DesignTokens.Colors.border.frame(height: 1)
                }

                Spacer(minLength: DesignTokens.Spacing.huge)

                ButtonPrimary("Who's Coming", icon: "arrow.right", iconEdge: .trailing, action: onNext)
                    .disabled(!draft.canLeaveDetails)
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.top, DesignTokens.Layout.fieldTopInset)
        .background(DesignTokens.Colors.field.ignoresSafeArea())
        .dismissesKeyboardOnTap()
        .onAppear { focus = .name }
    }
}

#Preview {
    CreateEventView(draft: {
        let d = EventDraft(organiserId: MockData.ivy.id)
        d.name = ""
        return d
    }())
}
