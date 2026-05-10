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

    func login(email: String, password: String) async -> Bool {
        do {
            let result = try await auth.signIn(withEmail: email, password: password)
            currentUserId = result.user.uid

            await fetchCurrentUser()

            let username = currentUser?.username ?? "Unknown"

            FirestoreService.shared.addEventLog(
                type: "USER_LOGIN",
                message: "\(username) logged into the system",
                performedByUsername: username
            ) { _ in }

            errorMessage = ""
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func signUp(username: String, email: String, password: String) async -> Bool {
        do {
            let result = try await auth.createUser(withEmail: email, password: password)
            let uid = result.user.uid

            try await db.collection("users").document(uid).setData([
                "username": username,
                "email": email,
                "role": "user",
                "isApproved": false,
                "isBlocked": false,
                "createdAt": Timestamp()
            ])
            FirestoreService.shared.addNotification(
                receiverUid: "",
                roleTarget: "admin",
                type: "pending user approval",
                message: "New user \(username) is waiting for approval"
            ) { _ in }

            currentUserId = uid
            await fetchCurrentUser()

            FirestoreService.shared.addEventLog(
                type: "USER_REGISTERED",
                message: "\(username) created a new account",
                performedByUsername: username
            ) { _ in }

            errorMessage = ""
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
    
    func loadCurrentSession() async {
        if let user = auth.currentUser {
            currentUserId = user.uid
            await fetchCurrentUser()
        } else {
            currentUserId = nil
            currentUser = nil
        }
    }

    func updateUsername(newUsername: String) async -> Bool {
        guard let uid = currentUserId else {
            errorMessage = "User not found."
            return false
        }

        do {
            try await db.collection("users").document(uid).updateData([
                "username": newUsername
            ])

            if let user = currentUser {
                currentUser = FirebaseUser(
                    id: user.id,
                    username: newUsername,
                    email: user.email,
                    role: user.role,
                    isApproved: user.isApproved,
                    isBlocked: user.isBlocked
                )
            }

            FirestoreService.shared.addEventLog(
                type: "UPDATE_PROFILE",
                message: "\(newUsername) updated username",
                performedByUsername: newUsername
            ) { _ in }

            errorMessage = ""
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func updateEmail(newEmail: String) async -> Bool {
        guard let firebaseUser = auth.currentUser else {
            errorMessage = "User not found."
            return false
        }

        do {
            try await firebaseUser.sendEmailVerification(beforeUpdatingEmail: newEmail)

            errorMessage = "Verification email sent. Please confirm to update email."
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func updatePassword(newPassword: String) async -> Bool {
        guard let firebaseUser = auth.currentUser else {
            errorMessage = "User not found."
            return false
        }

        do {
            try await firebaseUser.updatePassword(to: newPassword)

            let username = currentUser?.username ?? "Unknown"
            FirestoreService.shared.addEventLog(
                type: "UPDATE_PROFILE",
                message: "\(username) updated password",
                performedByUsername: username
            ) { _ in }

            errorMessage = ""
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func logout() {
        let username = currentUser?.username ?? "Unknown"

        FirestoreService.shared.addEventLog(
            type: "USER_LOGOUT",
            message: "\(username) logged out",
            performedByUsername: username
        ) { _ in }

        try? auth.signOut()
        currentUserId = nil
        currentUser = nil
    }

    func fetchCurrentUser() async {
        guard let uid = currentUserId else {
            errorMessage = "Missing user ID."
            return
        }

        do {
            let document = try await db.collection("users").document(uid).getDocument()

            guard document.exists else {
                errorMessage = "User document not found in Firestore."
                currentUser = nil
                return
            }

            guard let data = document.data() else {
                errorMessage = "User data is empty."
                currentUser = nil
                return
            }

            currentUser = FirebaseUser(
                id: uid,
                username: data["username"] as? String ?? "",
                email: data["email"] as? String ?? "",
                role: data["role"] as? String ?? "user",
                isApproved: data["isApproved"] as? Bool ?? false,
                isBlocked: data["isBlocked"] as? Bool ?? false
            )

            errorMessage = ""

        } catch {
            errorMessage = error.localizedDescription
            currentUser = nil
        }
    }
}
