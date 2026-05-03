import Foundation
import FirebaseFirestore

struct AppNotification: Identifiable {
    let id: String
    let receiverUid: String
    let roleTarget: String
    let type: String
    let message: String
    let createdAt: Date
    let isRead: Bool

    init(id: String, data: [String: Any]) {
        self.id = id
        self.receiverUid = data["receiverUid"] as? String ?? ""
        self.roleTarget = data["roleTarget"] as? String ?? ""
        self.type = data["type"] as? String ?? "UNKNOWN"
        self.message = data["message"] as? String ?? ""

        if let timestamp = data["createdAt"] as? Timestamp {
            self.createdAt = timestamp.dateValue()
        } else {
            self.createdAt = Date()
        }

        self.isRead = data["isRead"] as? Bool ?? false
    }
}
