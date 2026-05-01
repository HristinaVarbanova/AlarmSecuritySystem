import Foundation
import FirebaseAuth
import FirebaseFirestore
import Observation

@Observable
class AuthViewModel {
    var errorMessage: String = ""
    var currentUserId: String?
    var currentUser: FirebaseUser?
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()

    // LOGIN
    func login(email: String, password: String) async -> Bool {
        do {
            let result = try await auth.signIn(withEmail: email, password: password)
            currentUserId = result.user.uid
            await fetchCurrentUser()
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
    // FETCH USER DATA FROM FIRESTORE
    func fetchCurrentUser() async {
        guard let uid = currentUserId else { return }

        do {
            let document = try await db.collection("users").document(uid).getDocument()

            guard let data = document.data() else { return }

            let user = FirebaseUser(
                id: uid,
                username: data["username"] as? String ?? "",
                email: data["email"] as? String ?? "",
                role: data["role"] as? String ?? "user",
                isApproved: data["isApproved"] as? Bool ?? false,
                isBlocked: data["isBlocked"] as? Bool ?? false
            )

            self.currentUser = user

        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
