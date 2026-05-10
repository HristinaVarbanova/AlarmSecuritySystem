import Foundation
import FirebaseFirestore

struct SystemSettings {
    let systemPin: String

    let workStartHour: Int
    let workStartMinute: Int

    let workEndHour: Int
    let workEndMinute: Int

    let updatedBy: String
    let updatedAt: Date

    init(data: [String: Any]) {
        self.systemPin = data["systemPin"] as? String ?? ""

        self.workStartHour = data["workStartHour"] as? Int ?? 8
        self.workStartMinute = data["workStartMinute"] as? Int ?? 0

        self.workEndHour = data["workEndHour"] as? Int ?? 18
        self.workEndMinute = data["workEndMinute"] as? Int ?? 0

        self.updatedBy = data["updatedBy"] as? String ?? "Unknown"

        if let timestamp = data["updatedAt"] as? Timestamp {
            self.updatedAt = timestamp.dateValue()
        } else {
            self.updatedAt = Date()
        }
    }
}
