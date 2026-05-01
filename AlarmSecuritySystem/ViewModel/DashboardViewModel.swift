import Foundation
import Observation

@Observable
final class DashboardViewModel {
    var systemState: SystemState?
    var isLoading = false
    var errorMessage = ""

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

    var systemStatusText: String {
        guard let systemState else { return "Unknown" }
        return systemState.isArmed ? "Armed" : "Disarmed"
    }
}
