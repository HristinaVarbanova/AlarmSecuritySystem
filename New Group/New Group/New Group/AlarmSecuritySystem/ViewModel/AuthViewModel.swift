import Foundation
import FirebaseAuth
import FirebaseFirestore
import Observation

@Observable
class AuthViewModel {
    var errorMessage: String = ""
    var currentUserId: String?

    private let auth = Auth.auth()
    private let db = Firestore.firestore()

    // LOGIN
    func login(email: String, password: String) async -> Bool {
        do {
            let result = try await auth.signIn(withEmail: email, password: password)
            currentUserId = result.user.uid
            errorMessage = ""
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    // SIGNUP
    func signUp(username: String, email: String, password: String) async -> Bool {
        do {
            let result = try await auth.createUser(withEmail: email, password: password)

            let uid = result.user.uid

            // запис в Firestore
            try await db.collection("users").document(uid).setData([
                "username": username,
                "email": email,
                "role": "user",
                "isApproved": false,
                "isBlocked": false,
                "createdAt": Timestamp()
            ])

            currentUserId = uid
            errorMessage = ""

            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    // LOGOUT
    func logout() {
        try? auth.signOut()
        currentUserId = nil
    }
}
