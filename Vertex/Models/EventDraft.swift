import Foundation
import Observation

/// What the three creation sheets are filling in. Nothing exists server-side
/// until step 3 sends, so this is the only home for it until then.
@Observable
final class EventDraft {
    var name = ""
    var place = ""
    var duration: Event.Duration = .evening
    var invitedIds: Set<UserID> = []
    /// Days the organiser marked for themselves, normalised to midnight.
    var selectedDays: Set<Date> = []
    /// The hours each proposed run of days runs between, keyed by its first day.
    /// A range whose first day moves — because an earlier day was added to it —
    /// falls back to the default rather than carrying the old time onto new days.
    var times: [Date: TimeRange] = [:]

    let organiserId: UserID

    init(organiserId: UserID) {
        self.organiserId = organiserId
    }

    var canLeaveDetails: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }
    var canLeaveInvites: Bool { !invitedIds.isEmpty }
    var canSend: Bool { !selectedDays.isEmpty }

    func toggleInvite(_ uid: UserID) {
        if invitedIds.contains(uid) { invitedIds.remove(uid) } else { invitedIds.insert(uid) }
    }

    func toggleDay(_ day: Date) {
        let key = Calendar.current.startOfDay(for: day)
        if selectedDays.contains(key) { selectedDays.remove(key) } else { selectedDays.insert(key) }
        // Dropping a day can dissolve the range it keyed, so don't leave its
        // hours behind to be picked up by an unrelated range later.
        times = times.filter { selectedDays.contains($0.key) }
    }

    func isSelected(_ day: Date) -> Bool {
        selectedDays.contains(Calendar.current.startOfDay(for: day))
    }

    /// Consecutive selected days collapse into one range, which is what the
    /// "Your times" list and the proposed slots are built from.
    var proposedRanges: [ClosedRange<Date>] {
        let calendar = Calendar.current
        let sorted = selectedDays.sorted()
        var ranges: [ClosedRange<Date>] = []
        var start: Date?
        var previous: Date?

        for day in sorted {
            if let last = previous,
               calendar.date(byAdding: .day, value: 1, to: last).map({ calendar.isDate($0, inSameDayAs: day) }) == true {
                previous = day
            } else {
                if let s = start, let p = previous { ranges.append(s...p) }
                start = day
                previous = day
            }
        }
        if let s = start, let p = previous { ranges.append(s...p) }
        return ranges
    }
}

// MARK: - Times

extension EventDraft {

    func time(for range: ClosedRange<Date>) -> TimeRange {
        if let chosen = times[range.lowerBound] { return chosen }
        // 5pm is the doc's "from 5pm". A run of days ends mid-afternoon on the
        // last one, so a weekend finishes Sunday afternoon rather than Sunday night.
        return TimeRange(startHour: 17, endHour: range.spansDays ? 16 : 23)
    }

    func setTime(_ time: TimeRange, for range: ClosedRange<Date>) {
        times[range.lowerBound] = time
    }

    /// The absolute window a range's slot covers. On a single day an end at or
    /// before the start means it runs past midnight — 11pm to 2am is a real answer.
    func slotDates(for range: ClosedRange<Date>) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let time = time(for: range)
        let start = calendar.date(
            bySettingHour: time.startHour, minute: 0, second: 0, of: range.lowerBound
        ) ?? range.lowerBound

        var lastDay = range.upperBound
        if !range.spansDays, time.endHour <= time.startHour {
            lastDay = calendar.date(byAdding: .day, value: 1, to: lastDay) ?? lastDay
        }
        let end = calendar.date(
            bySettingHour: time.endHour, minute: 0, second: 0, of: lastDay
        ) ?? lastDay

        return (start, end)
    }
}

/// The hours one proposed run of days runs between. Hour granularity only —
/// "when could you do it?" doesn't need minutes, and it keeps the row to two taps.
struct TimeRange: Hashable {
    var startHour: Int
    var endHour: Int

    /// "5:00 PM" or "17.00", whichever the device is set to. Minutes are carried
    /// even though they're always zero — a bare "17" next to a "Wed 19 — Thu 20"
    /// label reads as another date.
    static func label(hour: Int) -> String {
        let calendar = Calendar.current
        let date = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: .now) ?? .now
        return date.formatted(.dateTime.hour().minute())
    }
}

private extension ClosedRange<Date> {
    var spansDays: Bool {
        !Calendar.current.isDate(lowerBound, inSameDayAs: upperBound)
    }
}
