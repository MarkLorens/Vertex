import Foundation

/// Sample content taken from the design doc, so screens can be driven by data
/// before Firestore exists. Dates are relative to now — a fixed date would put
/// the Upcoming countdown in the past within a week.
///
/// Not wrapped in `#if DEBUG` on purpose: the app currently runs on this. Guard
/// it once a real repository is in place.
enum MockData {}

// MARK: - People

extension MockData {
    /// The signed-in user, from the sign-in screen.
    static let ivy = User(id: "u_ivy", email: "ivy.marsh@hey.com", username: "Ivy Marsh", avatarColorIndex: 6)
    static let sam = User(id: "u_sam", email: "sam.reese@hey.com", username: "Sam Reese", avatarColorIndex: 1)
    static let jo = User(id: "u_jo", email: "jo.mackie@hey.com", username: "Jo Mackie", avatarColorIndex: 3)
    static let theo = User(id: "u_theo", email: "theo.okafor@hey.com", username: "Theo Okafor", avatarColorIndex: 5)
    static let ada = User(id: "u_ada", email: "ada.kade@hey.com", username: "Ada Kade", avatarColorIndex: 7)
    static let nina = User(id: "u_nina", email: "nina.brandt@hey.com", username: "Nina Brandt", avatarColorIndex: 0)
    static let dev = User(id: "u_dev", email: "dev.patel@hey.com", username: "Dev Patel", avatarColorIndex: 2)
    static let ren = User(id: "u_ren", email: "ren.kaur@hey.com", username: "Ren Kaur", avatarColorIndex: 4)
    static let mara = User(id: "u_mara", email: "mara.ali@hey.com", username: "Mara Ali", avatarColorIndex: 6)

    static let everyone: [User] = [ivy, sam, jo, theo, ada, nina, dev, ren, mara]

    static func user(_ id: UserID) -> User? { everyone.first { $0.id == id } }

    /// The notes shown beside friends on the invite screen.
    static let friendNotes: [FriendNote] = [
        FriendNote(id: nina.id, note: "Usually says maybe"),
        FriendNote(id: dev.id, note: "Has the big tent"),
        FriendNote(id: ren.id, note: "Drives"),
    ]
}

// MARK: - Events

extension MockData {
    /// The decided event the Upcoming screen counts down to.
    static let rooftopBirthday = decided(
        id: "e_rooftop",
        name: "Sam's rooftop birthday",
        place: "Ida's roof · 14 Lark St",
        duration: .evening,
        organiser: sam,
        startsIn: 3, hour: 20,
        going: [sam, jo, theo, ada, dev, ivy],
        undecided: [nina]
    )

    static let leavingDrinks = decided(
        id: "e_drinks",
        name: "Ren's leaving drinks",
        place: "The Fox",
        duration: .evening,
        organiser: ren,
        startsIn: 21, hour: 19, minute: 30,
        going: [ada, nina, dev, ren, sam, jo, theo, mara, ivy],
        undecided: []
    )

    static let sundayRoast = decided(
        id: "e_roast",
        name: "Sunday roast at Mum's",
        place: "42 Willow Rd",
        duration: .allDay,
        organiser: ivy,
        startsIn: 44, hour: 13,
        going: [sam, nina, dev, ren, ivy],
        undecided: []
    )

    /// Mid-vote. Seven in, five have cast votes, four have hit Finish Voting —
    /// which is why the tallies read "2 waiting" while the list says "4 of 7".
    /// Ivy hasn't voted, so this is the one wearing the "Needs you" pill.
    static let campingWeekend: EventDetail = {
        let people = [ivy, sam, jo, theo, ada, nina, dev]
        let event = Event(
            id: "e_camping",
            name: "Camping weekend",
            place: "Somewhere in the Peaks",
            duration: .weekend,
            organiserId: sam.id,
            createdAt: .daysAgo(4),
            status: .voting,
            availabilityClosesAt: .daysAgo(1),
            votingClosesAt: .inDays(3, hour: 20),
            round: 1,
            participantIds: people.map(\.id),
            decided: nil,
            cancellation: nil
        )

        let finished: Set<UserID> = [sam.id, jo.id, theo.id, ada.id]
        let participants = people.map {
            participant($0, status: .going, submittedAvailability: true, finished: finished.contains($0.id))
        }

        let slots = [
            Slot(id: "s_sep12", start: .inDays(41, hour: 17), end: .inDays(43, hour: 16),
                 proposedBy: sam.id,
                 votes: [sam.id: true, jo.id: true, theo.id: true, ada.id: true, nina.id: false]),
            Slot(id: "s_sep19", start: .inDays(48, hour: 17), end: .inDays(50, hour: 16),
                 proposedBy: jo.id,
                 votes: [sam.id: true, jo.id: true, theo.id: true, nina.id: true, ada.id: false]),
            Slot(id: "s_sep27", start: .inDays(56, hour: 9), end: .inDays(56, hour: 20),
                 proposedBy: ada.id,
                 votes: [sam.id: true, jo.id: false, theo.id: false, ada.id: false, nina.id: false]),
        ]

        return EventDetail(event: event, participants: participants, slots: slots)
    }()

    /// Everyone has finished — this is the one showing "Lock it in".
    static let filmClub: EventDetail = {
        let people = [ivy, jo, theo, ada, dev, ren]
        let event = Event(
            id: "e_film",
            name: "Film club",
            place: "Jo's place",
            duration: .evening,
            organiserId: jo.id,
            createdAt: .daysAgo(9),
            status: .voting,
            availabilityClosesAt: .daysAgo(5),
            votingClosesAt: .daysAgo(1),
            round: 1,
            participantIds: people.map(\.id),
            decided: nil,
            cancellation: nil
        )
        let participants = people.map {
            participant($0, status: .going, submittedAvailability: true, finished: true)
        }
        let slots = [
            Slot(id: "s_thu4", start: .inDays(12, hour: 19), end: .inDays(12, hour: 23),
                 proposedBy: jo.id,
                 votes: Dictionary(uniqueKeysWithValues: people.map { ($0.id, true) })),
            Slot(id: "s_thu11", start: .inDays(19, hour: 19), end: .inDays(19, hour: 23),
                 proposedBy: ada.id,
                 votes: Dictionary(uniqueKeysWithValues: people.map { ($0.id, $0.id == ada.id) })),
        ]
        return EventDetail(event: event, participants: participants, slots: slots)
    }()

    /// Barely started — two of five have finished, and Ivy is one of the ones
    /// still holding it up.
    static let boardGameNight: EventDetail = {
        let people = [ivy, jo, nina, dev, mara]
        let event = Event(
            id: "e_boardgames",
            name: "Board game night",
            place: "Dev's flat",
            duration: .evening,
            organiserId: jo.id,
            createdAt: .daysAgo(2),
            status: .voting,
            availabilityClosesAt: .daysAgo(1),
            votingClosesAt: .inDays(4, hour: 18),
            round: 1,
            participantIds: people.map(\.id),
            decided: nil,
            cancellation: nil
        )
        let finished: Set<UserID> = [jo.id, dev.id]
        let participants = people.map {
            participant($0, status: .going, submittedAvailability: true, finished: finished.contains($0.id))
        }
        let slots = [
            Slot(id: "s_fri", start: .inDays(6, hour: 19), end: .inDays(6, hour: 23),
                 proposedBy: jo.id, votes: [jo.id: true, dev.id: true]),
            Slot(id: "s_sat", start: .inDays(7, hour: 19), end: .inDays(7, hour: 23),
                 proposedBy: dev.id, votes: [jo.id: false, dev.id: true]),
        ]
        return EventDetail(event: event, participants: participants, slots: slots)
    }()

    // MARK: Planning-flow states

    /// 3e — everyone has finished and the top two are level, so `isDraw()` fires.
    static let drawnEvent: EventDetail = {
        var detail = campingWeekend
        detail.event.name = "Camping weekend"
        for index in detail.participants.indices {
            detail.participants[index].votingFinishedAt = .daysAgo(1)
        }
        // Both weekends land on 4 yes / 3 no, but backed by different people —
        // an identical set on each row reads like a rendering bug.
        detail.slots[0].votes = votes(yes: [sam, jo, dev, ivy], no: [theo, ada, nina])
        detail.slots[1].votes = votes(yes: [theo, ada, nina, ivy], no: [sam, jo, dev])
        detail.slots[2].votes = votes(yes: [sam], no: [jo, theo, ada, nina, dev, ivy])
        return detail
    }()

    /// 3f — the run-off itself, two slots at round 2 and nobody finished yet.
    static let runoffEvent: EventDetail = {
        var detail = drawnEvent
        detail.event.round = 2
        detail.event.status = .voting
        detail.event.votingClosesAt = .now.addingTimeInterval(4 * 3600)
        for index in detail.participants.indices {
            detail.participants[index].votingFinishedAt =
                [sam.id, jo.id, theo.id, ada.id, nina.id].contains(detail.participants[index].id)
                ? .minutesAgo(30) : nil
        }
        let contenders = Array(detail.slots.prefix(2))
        detail.slots += contenders.map {
            Slot(id: "\($0.id)_r2", start: $0.start, end: $0.end, proposedBy: $0.proposedBy, round: 2,
                 votes: votes(yes: [sam, jo, theo], no: [ada, nina]))
        }
        return detail
    }()

    /// 3g — settled, so the alarm panel and "Cancel event" are in play.
    static let settledEvent: EventDetail = {
        var detail = drawnEvent
        let winner = detail.slots[1]
        detail.event.status = .decided
        detail.event.place = "Peak District"
        detail.event.decided = Event.DecidedSlot(slotId: winner.id, start: winner.start, end: winner.end)
        detail.slots[1].votes = votes(yes: [sam, jo, theo, ada, dev, ivy], no: [nina])
        if let ninaIndex = detail.participants.firstIndex(where: { $0.id == nina.id }) {
            detail.participants[ninaIndex].status = .invited
        }
        if let mine = detail.participants.firstIndex(where: { $0.id == ivy.id }) {
            detail.participants[mine].alarm = Alarm(enabled: true, offset: .twoHours, sound: "Campfire")
        }
        return detail
    }()

    /// 3h — Ren has put cancelling to the group; three of seven are in favour.
    static let cancellingEvent: EventDetail = {
        var detail = settledEvent
        detail.event.participantIds = [ivy, sam, jo, theo, ada, nina, ren].map(\.id)
        detail.participants = [ivy, sam, jo, theo, ada, nina, ren].map {
            participant($0, status: .going, submittedAvailability: true, finished: true)
        }
        detail.event.cancellation = Cancellation(
            proposedBy: ren.id,
            reason: "Forecast is biblical. Let's move it.",
            createdAt: .minutesAgo(20),
            expiresAt: .now.addingTimeInterval(48 * 3600),
            votes: [ren.id: true, nina.id: true, ada.id: true, sam.id: false, jo.id: false, theo.id: false]
        )
        return detail
    }()

    private static func votes(yes: [User], no: [User]) -> [UserID: Bool] {
        var map: [UserID: Bool] = [:]
        for user in yes { map[user.id] = true }
        for user in no { map[user.id] = false }
        return map
    }

    static let decidedEvents: [EventDetail] = [rooftopBirthday, leavingDrinks, sundayRoast]
    static let decidingEvents: [EventDetail] = [campingWeekend, filmClub, boardGameNight]
    static let yourEvents: [EventDetail] = decidedEvents + decidingEvents

    /// What the Upcoming tab shows — the soonest settled event.
    static let upcoming: EventDetail? = decidedEvents
        .compactMap { detail in detail.event.decided.map { (detail, $0.start) } }
        .min { $0.1 < $1.1 }?.0
}

// MARK: - Notifications

extension MockData {
    static let pendingFriendRequest = FriendRequest(
        id: "fr_mara",
        fromUid: mara.id,
        toUid: ivy.id,
        status: .pending,
        createdAt: .minutesAgo(2)
    )

    static let notifications: [AppNotification] = [
        AppNotification(id: "n_1", type: .friendRequest, actorUid: mara.id,
                        eventId: nil, requestId: pendingFriendRequest.id,
                        createdAt: .minutesAgo(2), readAt: nil),
        AppNotification(id: "n_2", type: .eventInvite, actorUid: theo.id,
                        eventId: "e_hike", requestId: nil,
                        createdAt: .minutesAgo(14), readAt: nil),
        AppNotification(id: "n_3", type: .eventInvite, actorUid: jo.id,
                        eventId: boardGameNight.id, requestId: nil,
                        createdAt: .daysAgo(1), readAt: .daysAgo(1)),
        AppNotification(id: "n_4", type: .friendAccepted, actorUid: ada.id,
                        eventId: nil, requestId: nil,
                        createdAt: .daysAgo(1), readAt: .daysAgo(1)),
    ]

    static var unreadNotificationCount: Int {
        notifications.filter(\.isUnread).count
    }
}

// MARK: - Builders

private extension MockData {
    static func participant(
        _ user: User,
        status: Participant.Status,
        submittedAvailability: Bool = false,
        finished: Bool = false
    ) -> Participant {
        Participant(
            id: user.id,
            status: status,
            username: user.username,
            avatarColorIndex: user.avatarColorIndex,
            invitedAt: .daysAgo(5),
            respondedAt: status == .invited ? nil : .daysAgo(4),
            availabilitySubmittedAt: submittedAvailability ? .daysAgo(3) : nil,
            votingFinishedAt: finished ? .daysAgo(1) : nil,
            alarm: nil
        )
    }

    static func decided(
        id: EventID,
        name: String,
        place: String,
        duration: Event.Duration,
        organiser: User,
        startsIn days: Int,
        hour: Int,
        minute: Int = 0,
        going: [User],
        undecided: [User]
    ) -> EventDetail {
        let start = Date.inDays(days, hour: hour, minute: minute)
        let end = start.addingTimeInterval(4 * 3600)
        let people = going + undecided
        let slotId = "\(id)_slot"

        let event = Event(
            id: id,
            name: name,
            place: place,
            duration: duration,
            organiserId: organiser.id,
            createdAt: .daysAgo(20),
            status: .decided,
            availabilityClosesAt: .daysAgo(16),
            votingClosesAt: .daysAgo(12),
            round: 1,
            participantIds: people.map(\.id),
            decided: Event.DecidedSlot(slotId: slotId, start: start, end: end),
            cancellation: nil
        )

        let participants =
            going.map { participant($0, status: .going, submittedAvailability: true, finished: true) }
            + undecided.map { participant($0, status: .invited, submittedAvailability: true, finished: true) }

        let slot = Slot(
            id: slotId, start: start, end: end, proposedBy: organiser.id,
            votes: Dictionary(uniqueKeysWithValues: people.map { ($0.id, true) })
        )

        return EventDetail(event: event, participants: participants, slots: [slot])
    }
}

private extension Date {
    static func inDays(_ days: Int, hour: Int, minute: Int = 0) -> Date {
        let calendar = Calendar.current
        let day = calendar.date(byAdding: .day, value: days, to: .now) ?? .now
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
    }

    static func daysAgo(_ days: Int) -> Date { .now.addingTimeInterval(-Double(days) * 86_400) }
    static func minutesAgo(_ minutes: Int) -> Date { .now.addingTimeInterval(-Double(minutes) * 60) }
}
