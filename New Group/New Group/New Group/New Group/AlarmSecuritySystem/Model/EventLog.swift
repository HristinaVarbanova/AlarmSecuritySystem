import Foundation
import SwiftData

@Model
final class EventLog {
    var username: String
    var eventType: String
    var details: String
    var timestamp: Date

    init(username: String, eventType: String, details: String, timestamp: Date = Date()) {
        self.username = username
        self.eventType = eventType
        self.details = details
        self.timestamp = timestamp
    }
}
