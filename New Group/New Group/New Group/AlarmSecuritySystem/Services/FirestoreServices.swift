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
