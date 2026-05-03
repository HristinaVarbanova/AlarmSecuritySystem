import Foundation
import Observation

@Observable
final class UserManagementViewModel {
    var users: [FirebaseUser] = []
    var isLoading = false
    var errorMessage = ""

    func loadUsers() {
        isLoading = true
        errorMessage = ""

        FirestoreService.shared.fetchUsers { result in
            DispatchQueue.main.async {
                self.isLoading = false

                switch result {
                case .success(let users):
                    self.users = users

                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func updateUser(
        userId: String,
        isApproved: Bool,
        isBlocked: Bool,
        actionType: String,
        adminUsername: String
    ) {
        FirestoreService.shared.updateUserStatus(
            userId: userId,
            isApproved: isApproved,
            isBlocked: isBlocked
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.addAdminEventLog(
                        actionType: actionType,
                        adminUsername: adminUsername
                    )

                    self.addUserNotificationIfNeeded(
                        userId: userId,
                        actionType: actionType
                    )

                    self.loadUsers()

                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func addAdminEventLog(
        actionType: String,
        adminUsername: String
    ) {
        FirestoreService.shared.addEventLog(
            type: actionType,
            message: "\(adminUsername) changed user status",
            performedByUsername: adminUsername
        ) { _ in }
    }

    private func addUserNotificationIfNeeded(
        userId: String,
        actionType: String
    ) {
        switch actionType {
        case "BLOCK_USER":
            FirestoreService.shared.addNotification(
                receiverUid: userId,
                roleTarget: "user",
                type: "USER BLOCKED",
                message: "Your account has been blocked"
            ) { _ in }

        case "UNBLOCK_USER":
            FirestoreService.shared.addNotification(
                receiverUid: userId,
                roleTarget: "user",
                type: "USER UNBLOCKED",
                message: "Your account has been unblocked"
            ) { _ in }

        default:
            break
        }
    }
}
