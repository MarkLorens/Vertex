import Foundation

// Firestore document IDs are strings. These alias rather than wrap them so the
// types stay Codable for free and read as documentation at call sites.
typealias UserID = String
typealias EventID = String
typealias SlotID = String
typealias RequestID = String
typealias NotificationID = String
