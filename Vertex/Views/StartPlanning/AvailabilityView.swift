import SwiftUI

/// 3c — tap the days that work. Consecutive taps collapse into ranges, which
/// become the slots everyone votes on.
struct AvailabilityView: View {
    @Bindable var draft: EventDraft
    var isSending = false
    var onBack: () -> Void = {}
    var onSend: () -> Void = {}

    @State private var month: Date = .now

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
                Text("Tap the days that work. Everyone else adds theirs on top.")
                    .textStyle(DesignTokens.Typography.callout)
                    .foregroundStyle(DesignTokens.Colors.onFieldMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, DesignTokens.Layout.fieldPadding)
            .padding(.top, 22)
            .padding(.bottom, 18)

            SheetSurface(topPadding: DesignTokens.Layout.sheetPadding) {
                MonthGrid(month: $month, isSelected: draft.isSelected, onTap: draft.toggleDay)

                RuledLabel(title: "Your times")
                    .padding(.top, 18)
                    .padding(.bottom, DesignTokens.Spacing.lg)

                VStack(spacing: DesignTokens.Spacing.md) {
                    ForEach(draft.proposedRanges, id: \.lowerBound) { range in
                        rangeRow(range)
                    }
                }

                Spacer(minLength: DesignTokens.Spacing.huge)

                ButtonPrimary(isSending ? "Sending…" : "Send to the group", action: onSend)
                    .disabled(!draft.canSend || isSending)
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.top, DesignTokens.Layout.fieldTopInset)
        .background(DesignTokens.Colors.field.ignoresSafeArea())
    }

    private func rangeRow(_ range: ClosedRange<Date>) -> some View {
        HStack(spacing: DesignTokens.Spacing.xl) {
            Text(Self.label(for: range))
                .textStyle(DesignTokens.Typography.calloutStrong)
                .foregroundStyle(DesignTokens.Colors.ink)
            Spacer(minLength: 0)
            // The doc's "from 5pm" — a per-range start time isn't collected yet.
            Text("from 5pm")
                .textStyle(DesignTokens.Typography.caption)
                .foregroundStyle(DesignTokens.Colors.inkTertiary)
        }
        .padding(.horizontal, DesignTokens.Spacing.xxl)
        .padding(.vertical, DesignTokens.Spacing.xl)
        .background(DesignTokens.Colors.card, in: .rect(cornerRadius: 16, style: .continuous))
        .shadow(DesignTokens.Elevation.card)
    }

    static func label(for range: ClosedRange<Date>) -> String {
        let style = Date.FormatStyle.dateTime.weekday(.abbreviated).day()
        let start = range.lowerBound.formatted(style)
        guard !Calendar.current.isDate(range.lowerBound, inSameDayAs: range.upperBound) else { return start }
        return "\(start) — \(range.upperBound.formatted(style))"
    }
}

/// A single month, Monday-first, with the days the user has picked filled in.
struct MonthGrid: View {
    @Binding var month: Date
    let isSelected: (Date) -> Bool
    let onTap: (Date) -> Void

    private let calendar: Calendar = {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        return calendar
    }()

    private var days: [Date?] {
        guard let interval = calendar.dateInterval(of: .month, for: month) else { return [] }
        let first = interval.start
        let count = calendar.range(of: .day, in: .month, for: month)?.count ?? 0
        // Monday-first, so shift Sunday (weekday 1) to the end of the week.
        let leading = (calendar.component(.weekday, from: first) + 5) % 7
        let dates = (0..<count).compactMap { calendar.date(byAdding: .day, value: $0, to: first) }
        return Array(repeating: nil, count: leading) + dates
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(month.formatted(.dateTime.month(.wide)))
                    .textStyle(DesignTokens.Typography.rowTitle)
                    .foregroundStyle(DesignTokens.Colors.ink)
                Spacer()
                HStack(spacing: DesignTokens.Spacing.xxxl) {
                    stepper("chevron.left", -1, DesignTokens.Colors.ink.opacity(0.3))
                    stepper("chevron.right", 1, DesignTokens.Colors.ink.opacity(0.55))
                }
            }
            .padding(.bottom, DesignTokens.Spacing.xxl)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: DesignTokens.Spacing.sm), count: 7),
                      spacing: DesignTokens.Spacing.sm) {
                ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol)
                        .textStyle(DesignTokens.Typography.micro)
                        .foregroundStyle(DesignTokens.Colors.inkFaint)
                }
            }
            .padding(.bottom, DesignTokens.Spacing.md)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: DesignTokens.Spacing.sm), count: 7),
                      spacing: DesignTokens.Spacing.sm) {
                ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                    if let day { dayCell(day) } else { Color.clear.frame(height: 34) }
                }
            }
        }
    }

    private var weekdaySymbols: [String] {
        // "M T W T F S S" — the doc uses single letters, which collide by design.
        let symbols = calendar.veryShortWeekdaySymbols
        return (0..<7).map { symbols[($0 + calendar.firstWeekday - 1) % 7] }
    }

    private func dayCell(_ day: Date) -> some View {
        let selected = isSelected(day)
        let past = day < calendar.startOfDay(for: .now)
        return Button { onTap(day) } label: {
            Text("\(calendar.component(.day, from: day))")
                .textStyle(selected ? DesignTokens.Typography.calloutStrong : DesignTokens.Typography.callout)
                .foregroundStyle(selected
                                 ? DesignTokens.Colors.onField
                                 : DesignTokens.Colors.ink.opacity(past ? 0.28 : 0.7))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background {
                    if selected {
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.chip, style: .continuous)
                            .fill(DesignTokens.Colors.accent)
                    }
                }
        }
        .buttonStyle(.plain)
        .disabled(past)
    }

    private func stepper(_ symbol: String, _ delta: Int, _ color: Color) -> some View {
        Button {
            if let next = calendar.date(byAdding: .month, value: delta, to: month) { month = next }
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(color)
        }
        .buttonStyle(.plain)
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
