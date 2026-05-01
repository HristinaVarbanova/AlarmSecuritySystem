import Foundation
import FirebaseFirestore

struct SystemState {
    let isArmed: Bool
    let doorLocked: Bool
    let isLocked: Bool
    let lastChangedBy: String
    let changedAt: Date

    init(data: [String: Any]) {
        self.isArmed = data["isArmed"] as? Bool ?? false
        self.doorLocked = data["doorLocked"] as? Bool ?? false
        self.isLocked = data["isLocked"] as? Bool ?? false
        self.lastChangedBy = data["lastChangedBy"] as? String ?? "Unknown"

        if let timestamp = data["changedAt"] as? Timestamp {
            self.changedAt = timestamp.dateValue()
        } else {
            self.changedAt = Date()
        }
    }
}
