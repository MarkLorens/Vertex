import Foundation

/// Time remaining, split into the four units the hero renders. Clamps at zero —
/// a settled event whose date has passed reads 00d rather than counting up.
struct Countdown: Hashable {
    let days: Int
    let hours: Int
    let minutes: Int
    let seconds: Int

    init(until target: Date, from now: Date = .now) {
        let remaining = max(0, Int(target.timeIntervalSince(now)))
        days = remaining / 86_400
        hours = remaining % 86_400 / 3_600
        minutes = remaining % 3_600 / 60
        seconds = remaining % 60
    }

    var hasElapsed: Bool {
        days == 0 && hours == 0 && minutes == 0 && seconds == 0
    }
}
