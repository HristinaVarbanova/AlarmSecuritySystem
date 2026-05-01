import Foundation
import Observation

@Observable
final class SystemStatusViewModel {
    var systemState: SystemState?
    var errorMessage = ""
    var isLoading = false

    func loadSystemState() {
        isLoading = true
        errorMessage = ""

        FirestoreService.shared.fetchSystemStateModel { result in
            DispatchQueue.main.async {
                self.isLoading = false

                switch result {
                case .success(let state):
                    self.systemState = state

                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
