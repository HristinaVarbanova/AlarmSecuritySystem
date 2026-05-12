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
        type: String,
        adminUsername: String
    ) {
        let targetUsername = users.first(where: { $0.id == userId })?.username ?? "Unknown"

        FirestoreService.shared.updateUserStatus(
            userId: userId,
            isApproved: isApproved,
            isBlocked: isBlocked
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.addAdminEventLog(
                        type: type,
                        adminUsername: adminUsername,
                        targetUsername: targetUsername
                    )

                    self.loadUsers()

                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func addAdminEventLog(
        type: String,
        adminUsername: String,
        targetUsername: String
    ) {
        let message: String

        switch type {
        case EventLogType.approveUser.rawValue:
            message = "\(adminUsername) approved user \(targetUsername)"

        case EventLogType.blockUser.rawValue:
            message = "\(adminUsername) blocked user \(targetUsername)"

        case EventLogType.unblockUser.rawValue:
            message = "\(adminUsername) unblocked user \(targetUsername)"

        default:
            message = "\(adminUsername) updated user \(targetUsername)"
        }

        FirestoreService.shared.addEventLog(
            type: type,
            message: message,
            performedByUsername: adminUsername
        ) { _ in }
    }
}
