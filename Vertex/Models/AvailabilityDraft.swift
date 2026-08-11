import Foundation
import Observation

/// The days and hours one person is picking. Used twice: by the organiser on the
/// last creation step, and by everyone else once they've accepted the invite.
@Observable
final class AvailabilityDraft {
    /// Normalised to midnight.
    var selectedDays: Set<Date> = []
    /// The hours each run of days runs between, keyed by its first day. A run
    /// whose first day moves — because an earlier day was added to it — falls
    /// back to the default rather than carrying the old time onto new days.
    var times: [Date: TimeRange] = [:]

    var isEmpty: Bool { selectedDays.isEmpty }

    func toggleDay(_ day: Date) {
        let key = Calendar.current.startOfDay(for: day)
        if selectedDays.contains(key) { selectedDays.remove(key) } else { selectedDays.insert(key) }
        // Dropping a day can dissolve the run it keyed, so don't leave its hours
        // behind to be picked up by an unrelated run later.
        times = times.filter { selectedDays.contains($0.key) }
    }

    func isSelected(_ day: Date) -> Bool {
        selectedDays.contains(Calendar.current.startOfDay(for: day))
    }

    var proposedRanges: [ClosedRange<Date>] { DayRuns.collapse(selectedDays) }

    func time(for range: ClosedRange<Date>) -> TimeRange {
        if let chosen = times[range.lowerBound] { return chosen }
        // 5pm is the doc's "from 5pm". A run of days ends mid-afternoon on the
        // last one, so a weekend finishes Sunday afternoon rather than Sunday night.
        let spansDays = !Calendar.current.isDate(range.lowerBound, inSameDayAs: range.upperBound)
        return TimeRange(startHour: 17, endHour: spansDays ? 16 : 23)
    }

    func setTime(_ time: TimeRange, for range: ClosedRange<Date>) {
        times[range.lowerBound] = time
    }

    func window(for range: ClosedRange<Date>) -> Availability.Window {
        Availability.Window(run: range, hours: time(for: range))
    }

    /// What gets written for this person once they send.
    func offer(from uid: UserID) -> Availability {
        Availability(
            id: uid,
            days: selectedDays.sorted(),
            windows: proposedRanges.map(window(for:))
        )
    }
}

/// The hours one run of days runs between. Hour granularity only — "when could
/// you do it?" doesn't need minutes, and it keeps the row to two taps.
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
