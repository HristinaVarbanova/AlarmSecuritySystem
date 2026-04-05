import Foundation
import SwiftData
import Observation

@Observable
class AuthViewModel {
    var loginError: String = ""
    var loggedInUser: AppUser?

    func login(username: String, password: String, users: [AppUser], modelContext: ModelContext) -> Bool {
        let cleanUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let user = users.first(where: {
            $0.username == cleanUsername && $0.password == password
        }) else {
            loginError = "Invalid username or password"
            return false
        }

        loginError = ""
        loggedInUser = user

        let log = EventLog(
            username: user.username,
            eventType: "Login",
            details: "\(user.username) logged into the mobile app"
        )
        modelContext.insert(log)

        return true
    }

    func signUp(username: String, password: String, users: [AppUser], modelContext: ModelContext) -> Bool {
        let cleanUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanUsername.isEmpty else {
            loginError = "Username cannot be empty"
            return false
        }

        let alreadyExists = users.contains { $0.username.lowercased() == cleanUsername.lowercased() }

        if alreadyExists {
            loginError = "Username already exists"
            return false
        }

        let newUser = AppUser(
            username: cleanUsername,
            password: password,
            role: .user
        )

        modelContext.insert(newUser)
        loggedInUser = newUser
        loginError = ""

        let log = EventLog(
            username: newUser.username,
            eventType: "Signup",
            details: "\(newUser.username) created a new account"
        )
        modelContext.insert(log)

        return true
    }

    func logout() {
        loggedInUser = nil
    }
}
