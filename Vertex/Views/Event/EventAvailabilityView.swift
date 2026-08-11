import SwiftUI

/// 3c for everyone who wasn't the organiser. Accepting an invite lands here, not
/// in the vote — there's nothing to vote on until the group's times are in.
struct EventAvailabilityView: View {
    @Bindable var store: EventStore
    var onBack: () -> Void = {}

    @State private var draft = AvailabilityDraft()

    private var detail: EventDetail { store.detail }
    private var outstanding: Int {
        max(0, store.event.participantCount - detail.submittedAvailabilityCount)
    }

    var body: some View {
        VStack(spacing: 0) {
            EventNav(title: store.event.name, showsOverflow: false, onBack: onBack)
                .padding(.horizontal, DesignTokens.Layout.screenPadding)
                .padding(.top, DesignTokens.Spacing.sm)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text(store.hasSubmittedAvailability ? "Your times are in" : "When could you do it?")
                    .textStyle(DesignTokens.Typography.title)
                    .foregroundStyle(DesignTokens.Colors.onField)
                Text(subtitle)
                    .textStyle(DesignTokens.Typography.callout)
                    .foregroundStyle(DesignTokens.Colors.onFieldMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, DesignTokens.Layout.fieldPadding)
            .padding(.top, 22)
            .padding(.bottom, 18)

            SheetSurface(topPadding: DesignTokens.Layout.sheetPadding) {
                if store.hasSubmittedAvailability {
                    waiting
                } else {
                    AvailabilityPicker(draft: draft)

                    Spacer(minLength: DesignTokens.Spacing.huge)

                    ButtonPrimary("Send my times") { store.submitAvailability(draft) }
                        .disabled(draft.isEmpty)

                    Text("Everyone's days get merged into the dates you'll vote on.")
                        .textStyle(DesignTokens.Typography.caption3)
                        .foregroundStyle(DesignTokens.Colors.inkSubtle)
                        .multilineTextAlignment(.center)
                        .padding(.top, 9)
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.top, DesignTokens.Layout.fieldTopInset)
        .background(DesignTokens.Colors.field.ignoresSafeArea())
    }

    private var subtitle: String {
        if store.hasSubmittedAvailability {
            return outstanding == 1
                ? "Waiting on one more person."
                : "Waiting on \(outstanding) more people."
        }
        return "Tap the days and time that work for you."
    }

    /// No picker to come back to — availability is one-shot, so this reports the
    /// gate rather than offering a way to fiddle with an answer already counted.
    private var waiting: some View {
        VStack(spacing: DesignTokens.Spacing.xxl) {
            HStack(spacing: DesignTokens.Spacing.lg) {
                ProgressTrack(
                    fraction: Double(detail.submittedAvailabilityCount)
                        / Double(max(1, store.event.participantCount)),
                    fill: DesignTokens.Colors.accent,
                    track: DesignTokens.Colors.track
                )
                Text("\(detail.submittedAvailabilityCount) of \(store.event.participantCount) in")
                    .textStyle(DesignTokens.Typography.caption3)
                    .foregroundStyle(DesignTokens.Colors.inkTertiary)
                    .fixedSize()
            }

            RuledLabel(title: "Still to answer")

            VStack(spacing: DesignTokens.Spacing.md) {
                ForEach(detail.activeParticipants.filter { !$0.hasSubmittedAvailability }) { person in
                    HStack(spacing: DesignTokens.Spacing.xl) {
                        AvatarView(avatar: person.avatar, diameter: 30)
                        Text(person.username)
                            .textStyle(DesignTokens.Typography.bodyLargeStrong)
                            .foregroundStyle(DesignTokens.Colors.ink)
                        Spacer(minLength: 0)
                    }
                }
            }

            Spacer(minLength: DesignTokens.Spacing.huge)

            Text("Voting opens the moment everyone's answered, or on \(store.event.availabilityClosesAt.formatted(.dateTime.weekday(.wide))) — whichever comes first.")
                .textStyle(DesignTokens.Typography.caption2)
                .foregroundStyle(DesignTokens.Colors.inkSubtle)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview("Picking") {
    EventAvailabilityView(store: EventStore(
        detail: MockData.gatheringEvent, currentUserId: MockData.ivy.id
    ))
}

#Preview("Waiting") {
    EventAvailabilityView(store: EventStore(
        detail: MockData.gatheringEvent, currentUserId: MockData.sam.id
    ))
}
