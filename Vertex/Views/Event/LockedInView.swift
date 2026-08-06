import SwiftUI

/// 3g — the date is settled. Alarm is per person, and "Cancel event" takes the
/// place "Finish voting" used to occupy.
struct LockedInView: View {
    @Bindable var store: EventStore
    var onBack: () -> Void = {}
    var onCancelEvent: () -> Void = {}

    private var detail: EventDetail { store.detail }

    private var settledLine: String? {
        guard let margin = store.settledMargin else { return nil }
        return margin.no > 0
            ? "Settled by \(margin.yes) votes to \(margin.no)"
            : "Settled — \(margin.yes) said yes"
    }

    private var attendance: String {
        let going = "\(detail.going.count) going"
        let thinking = detail.undecided
        switch thinking.count {
        case 0: return going
        case 1: return "\(going), \(thinking[0].username.split(separator: " ").first.map(String.init) ?? "one") hasn't said"
        default: return "\(going), \(thinking.count) haven't said"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            EventNav(title: store.event.name, onBack: onBack)
                .padding(.horizontal, DesignTokens.Layout.screenPadding)
                .padding(.top, DesignTokens.Spacing.sm)

            VStack(alignment: .leading, spacing: 0) {
                if let settledLine {
                    HStack(spacing: 7) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .heavy))
                            .foregroundStyle(DesignTokens.Colors.onField)
                        Text(settledLine.uppercased())
                            .textStyle(DesignTokens.Typography.eyebrow)
                            .foregroundStyle(DesignTokens.Colors.onField)
                    }
                    .padding(.bottom, DesignTokens.Spacing.lg)
                }

                if let decided = store.event.decided {
                    DesignTokens.Typography.numeral.text(Self.headline(decided.start))
                        .foregroundStyle(DesignTokens.Colors.onField)
                        .lineSpacing(-6)
                }

                Text("\(store.event.place) · \(attendance)")
                    .textStyle(DesignTokens.Typography.subtitle)
                    .foregroundStyle(DesignTokens.Colors.onField.opacity(0.75))
                    .padding(.top, DesignTokens.Spacing.lg)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, DesignTokens.Layout.fieldPadding)
            .padding(.top, 22)
            .padding(.bottom, DesignTokens.Spacing.huge)

            SheetSurface(topPadding: 22) {
                ScrollView {
                    VStack(spacing: 0) {
                        alarmHeader
                        offsets
                        settingsCard
                    }
                }
                .scrollIndicators(.hidden)

                Spacer(minLength: DesignTokens.Spacing.huge)

                ButtonPrimary("Cancel event", fill: .destructive, action: onCancelEvent)
                Text("Everyone gets a say — it's a group vote, not a delete button.")
                    .textStyle(DesignTokens.Typography.caption3)
                    .foregroundStyle(DesignTokens.Colors.inkSubtle)
                    .multilineTextAlignment(.center)
                    .padding(.top, 9)
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.top, DesignTokens.Layout.fieldTopInset)
        .background(DesignTokens.Colors.field.ignoresSafeArea())
    }

    private var alarmHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Wake me up for it")
                    .textStyle(DesignTokens.Typography.rowTitle)
                    .foregroundStyle(DesignTokens.Colors.ink)
                Text("A real alarm, not a notification")
                    .textStyle(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Colors.inkTertiary)
            }
            Spacer(minLength: 0)
            Toggle("", isOn: Binding(
                get: { store.alarm.enabled },
                set: { on in store.updateAlarm { $0.enabled = on } }
            ))
            .labelsHidden()
            .tint(DesignTokens.Colors.accent)
        }
        .padding(.bottom, DesignTokens.Spacing.xxl)
    }

    private var offsets: some View {
        FlowRow(spacing: DesignTokens.Spacing.md) {
            ForEach(Alarm.Offset.allCases, id: \.self) { offset in
                ChoiceChip(title: offset.label, isSelected: store.alarm.offset == offset) {
                    store.updateAlarm { $0.offset = offset }
                }
            }
        }
        .opacity(store.alarm.enabled ? 1 : 0.45)
        .disabled(!store.alarm.enabled)
        .padding(.bottom, DesignTokens.Spacing.huge)
    }

    private var settingsCard: some View {
        VStack(spacing: 0) {
            SettingsRow(title: "Alarm sound", detail: store.alarm.sound, accessory: .chevron)
            rule
            SettingsRow(title: "Add to Calendar", accessory: .toggle(Binding(
                get: { store.alarm.enabled },
                set: { on in store.updateAlarm { $0.enabled = on } }
            )))
            rule
            SettingsRow(title: "Nudge the undecided", accessory: .chevron)
                .disabled(detail.undecided.isEmpty)
                .opacity(detail.undecided.isEmpty ? 0.4 : 1)
        }
        .background(DesignTokens.Colors.card, in: .rect(cornerRadius: DesignTokens.Radius.card, style: .continuous))
        .shadow(DesignTokens.Elevation.card)
    }

    private var rule: some View {
        DesignTokens.Colors.ink.opacity(0.07)
            .frame(height: DesignTokens.Size.hairline)
            .padding(.leading, DesignTokens.Spacing.xxxl)
    }

    /// "Fri 19 Sep" over "5:00 PM" — two lines, as the doc sets it.
    static func headline(_ date: Date) -> String {
        let day = "\(SlotFormat.weekdayDay(date)) \(date.formatted(.dateTime.month(.abbreviated)))"
        return "\(day)\n\(date.formatted(.dateTime.hour().minute()))"
    }
}

struct SettingsRow: View {
    enum Accessory {
        case chevron
        case toggle(Binding<Bool>)
        case none
    }

    let title: String
    var detail: String?
    var accessory: Accessory = .none

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.xl) {
            Text(title)
                .textStyle(DesignTokens.Typography.bodyPlain)
                .foregroundStyle(DesignTokens.Colors.ink)
            Spacer(minLength: 0)
            if let detail {
                Text(detail)
                    .textStyle(DesignTokens.Typography.calloutStrong)
                    .foregroundStyle(DesignTokens.Colors.inkTertiary)
            }
            switch accessory {
            case .chevron:
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(DesignTokens.Colors.ink.opacity(0.25))
            case .toggle(let binding):
                Toggle("", isOn: binding)
                    .labelsHidden()
                    .tint(DesignTokens.Colors.accent)
            case .none:
                EmptyView()
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.xxxl)
        .padding(.vertical, DesignTokens.Spacing.xxl)
    }
}

#Preview {
    LockedInView(store: EventStore(detail: MockData.settledEvent, currentUserId: MockData.ivy.id))
}
