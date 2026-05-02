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
                    FirestoreService.shared.addEventLog(
                        type: actionType,
                        message: "\(adminUsername) changed user status",
                        performedByUsername: adminUsername
                    ) { _ in }

                    self.loadUsers()

                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
