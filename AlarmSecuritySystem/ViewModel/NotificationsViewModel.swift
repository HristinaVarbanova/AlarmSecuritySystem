import Foundation
import FirebaseFirestore
import Observation

@Observable
final class NotificationsViewModel {
    var notifications: [AppNotification] = []
    var isLoading = false
    var errorMessage = ""

    private var listener: ListenerRegistration?

    func startListening(for userId: String) {
        isLoading = true
        errorMessage = ""

        listener?.remove()

        listener = FirestoreService.shared.listenForNotifications(for: userId) { result in
            DispatchQueue.main.async {
                self.isLoading = false

                switch result {
                case .success(let notifications):
                    self.notifications = notifications

                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }
}
