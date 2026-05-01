
import Foundation
import FirebaseFirestore

struct FirebaseEventLog: Identifiable {
    let id: String
    let type: String
    let message: String
    let performedByUsername: String
    let createdAt: Date

    init(id: String, data: [String: Any]) {
        self.id = id
        self.type = data["type"] as? String ?? "UNKNOWN"
        self.message = data["message"] as? String ?? ""
        self.performedByUsername = data["performedByUsername"] as? String ?? "Unknown"

        if let timestamp = data["createdAt"] as? Timestamp {
            self.createdAt = timestamp.dateValue()
        } else {
            self.createdAt = Date()
        }
    }
}
