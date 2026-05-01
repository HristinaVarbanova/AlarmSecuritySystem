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

    func updateUser(userId: String, isApproved: Bool, isBlocked: Bool) {
        FirestoreService.shared.updateUserStatus(
            userId: userId,
            isApproved: isApproved,
            isBlocked: isBlocked
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.loadUsers()

                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
