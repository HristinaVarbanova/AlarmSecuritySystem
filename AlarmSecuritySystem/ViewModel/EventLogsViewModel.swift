import Foundation
import Observation

@Observable
final class EventLogsViewModel {
    var logs: [FirebaseEventLog] = []
    var isLoading = false
    var errorMessage = ""

    func loadLogs() {
        isLoading = true
        errorMessage = ""

        FirestoreService.shared.fetchEventLogModels { result in
            DispatchQueue.main.async {
                self.isLoading = false

                switch result {
                case .success(let logs):
                    self.logs = logs

                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
