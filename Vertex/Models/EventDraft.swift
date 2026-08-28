import Foundation
import Observation

/// What the three creation sheets are filling in. Nothing exists server-side
/// until step 3 sends, so this is the only home for it until then.
@Observable
final class EventDraft: AvailabilityPicking {
    var name = ""
    var place = ""
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

    var proposedRanges: [ClosedRange<Date>] { DayRuns.collapse(selectedDays) }
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

    /// The absolute window a range's slot covers.
    func slotDates(for range: ClosedRange<Date>) -> (start: Date, end: Date) {
        Availability.Window(run: range, hours: time(for: range)).dates
    }
}
