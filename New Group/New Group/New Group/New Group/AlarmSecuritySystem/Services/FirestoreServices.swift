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
