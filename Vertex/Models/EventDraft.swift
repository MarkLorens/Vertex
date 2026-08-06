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
