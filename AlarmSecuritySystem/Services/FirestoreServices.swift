import Foundation
import FirebaseFirestore

final class FirestoreService {
    static let shared = FirestoreService()
    
    private let db = Firestore.firestore()
    
    private init() {}
    
    func fetchSystemState(completion: @escaping (Result<[String: Any], Error>) -> Void) {
        db.collection("systemState").document("main").getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = snapshot?.data() else {
                let error = NSError(
                    domain: "FirestoreService",
                    code: 404,
                    userInfo: [NSLocalizedDescriptionKey: "System state document not found."]
                )
                completion(.failure(error))
                return
            }
            
            completion(.success(data))
        }
    }
    
    func fetchUsers(completion: @escaping (Result<[FirebaseUser], Error>) -> Void) {
        db.collection("users").getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let documents = snapshot?.documents else {
                completion(.success([]))
                return
            }

            let users: [FirebaseUser] = documents.map { document in
                let data = document.data()

                return FirebaseUser(
                    id: document.documentID,
                    username: data["username"] as? String ?? "",
                    email: data["email"] as? String ?? "",
                    role: data["role"] as? String ?? "user",
                    isApproved: data["isApproved"] as? Bool ?? false,
                    isBlocked: data["isBlocked"] as? Bool ?? false
                )
            }

            completion(.success(users))
        }
    }

    func updateUserStatus(
        userId: String,
        isApproved: Bool,
        isBlocked: Bool,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        db.collection("users")
            .document(userId)
            .updateData([
                "isApproved": isApproved,
                "isBlocked": isBlocked
            ]) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
    }
    func addNotification(
        receiverUid: String,
        roleTarget: String,
        type: String,
        message: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        db.collection("notifications")
            .addDocument(data: [
                "receiverUid": receiverUid,
                "roleTarget": roleTarget,
                "type": type,
                "message": message,
                "createdAt": Timestamp(),
                "isRead": false
            ]) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
    }

    func fetchNotifications(
        for userId: String,
        completion: @escaping (Result<[AppNotification], Error>) -> Void
    ) {
        db.collection("notifications")
            .whereField("receiverUid", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                let notifications = snapshot?.documents.map { document in
                    AppNotification(id: document.documentID, data: document.data())
                } ?? []

                completion(.success(notifications))
            }
    }
    
    func listenForNotifications(
        for userId: String,
        completion: @escaping (Result<[AppNotification], Error>) -> Void
    ) -> ListenerRegistration {
        return db.collection("notifications")
            .whereField("receiverUid", isEqualTo: userId)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Notifications listener error:", error.localizedDescription)
                    completion(.failure(error))
                    return
                }

                let notifications = snapshot?.documents.map { document in
                    AppNotification(
                        id: document.documentID,
                        data: document.data()
                    )
                } ?? []

                let sortedNotifications = notifications.sorted {
                    $0.createdAt > $1.createdAt
                }

                print("Notifications count:", sortedNotifications.count)

                completion(.success(sortedNotifications))
            }
    }
    
    func fetchAdminNotifications(
        completion: @escaping (Result<[AppNotification], Error>) -> Void
    ) {
        db.collection("notifications")
            .whereField("roleTarget", isEqualTo: "admin")
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                let notifications = snapshot?.documents.map { document in
                    AppNotification(id: document.documentID, data: document.data())
                } ?? []

                let sortedNotifications = notifications.sorted {
                    $0.createdAt > $1.createdAt
                }

                completion(.success(sortedNotifications))
            }
    }
    
    func incrementFailedAccessAttempts(
        completion: @escaping (Result<Int, Error>) -> Void
    ) {
        let ref = db.collection("systemState").document("main")

        db.runTransaction({ transaction, errorPointer in
            let snapshot: DocumentSnapshot

            do {
                try snapshot = transaction.getDocument(ref)
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }

            let current = snapshot.data()?["failedAccessAttempts"] as? Int ?? 0
            let updated = current + 1

            transaction.updateData([
                "failedAccessAttempts": updated
            ], forDocument: ref)

            return updated

        }) { result, error in
            if let error = error {
                completion(.failure(error))
            } else if let count = result as? Int {
                completion(.success(count))
            }
        }
    }
    func resetFailedAccessAttempts(
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        db.collection("systemState")
            .document("main")
            .updateData([
                "failedAccessAttempts": 0
            ]) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
    }
    
    func listenForAdminNotifications(
        completion: @escaping (Result<[AppNotification], Error>) -> Void
    ) -> ListenerRegistration {
        return db.collection("notifications")
            .whereField("roleTarget", isEqualTo: "admin")
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                let notifications = snapshot?.documents.map { document in
                    AppNotification(id: document.documentID, data: document.data())
                } ?? []

                let sortedNotifications = notifications.sorted {
                    $0.createdAt > $1.createdAt
                }

                completion(.success(sortedNotifications))
            }
    }
    
    func fetchSystemSettings(completion: @escaping (Result<SystemSettings, Error>) -> Void) {
        db.collection("systemSettings")
            .document("main")
            .getDocument { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let data = snapshot?.data() else {
                    completion(.failure(NSError(
                        domain: "FirestoreService",
                        code: 404,
                        userInfo: [NSLocalizedDescriptionKey: "System settings not found."]
                    )))
                    return
                }

                completion(.success(SystemSettings(data: data)))
            }
    }

    func updateSystemSettings(
        systemPin: String?,
        workStartHour: Int,
        workStartMinute: Int,
        workEndHour: Int,
        workEndMinute: Int,
        updatedBy: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        var data: [String: Any] = [
            "workStartHour": workStartHour,
            "workStartMinute": workStartMinute,
            "workEndHour": workEndHour,
            "workEndMinute": workEndMinute,
            "updatedBy": updatedBy,
            "updatedAt": Timestamp()
        ]

        // ако PIN не е празен → сменяме го
        if let pin = systemPin, !pin.isEmpty {
            data["systemPin"] = pin
        }

        db.collection("systemSettings")
            .document("main")
            .updateData(data) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
    }
    func fetchSystemStateModel(completion: @escaping (Result<SystemState, Error>) -> Void) {
        db.collection("systemState")
            .document("main")
            .getDocument { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let data = snapshot?.data() else {
                    let error = NSError(
                        domain: "FirestoreService",
                        code: 404,
                        userInfo: [NSLocalizedDescriptionKey: "System state not found."]
                    )
                    completion(.failure(error))
                    return
                }

                let state = SystemState(data: data)
                completion(.success(state))
            }
    }
    
    func updateSystemState(
        isArmed: Bool,
        doorLocked: Bool,
        changedBy: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        db.collection("systemState")
            .document("main")
            .updateData([
                "isArmed": isArmed,
                "doorLocked": doorLocked,
                "lastChangedBy": changedBy,
                "changedAt": Timestamp()
            ]) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
    }

    func addEventLog(
        type: String,
        message: String,
        performedByUsername: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        db.collection("eventLogs")
            .addDocument(data: [
                "type": type,
                "message": message,
                "performedByUsername": performedByUsername,
                "createdAt": Timestamp()
            ]) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
    }
    func fetchEventLogModels(completion: @escaping (Result<[FirebaseEventLog], Error>) -> Void) {
        db.collection("eventLogs")
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                let logs = snapshot?.documents.map { document in
                    FirebaseEventLog(id: document.documentID, data: document.data())
                } ?? []

                completion(.success(logs))
            }
    }
    
    func fetchEventLogs(completion: @escaping (Result<[[String: Any]], Error>) -> Void) {
        db.collection("eventLogs")
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                let documents = snapshot?.documents.map { $0.data() } ?? []
                completion(.success(documents))
            }
    }
}
