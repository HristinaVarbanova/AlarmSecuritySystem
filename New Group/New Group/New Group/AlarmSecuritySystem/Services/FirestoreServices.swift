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
