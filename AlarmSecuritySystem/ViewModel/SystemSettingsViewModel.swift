import Foundation
import Observation

@Observable
final class SystemSettingsViewModel {
    var systemPin = ""

    var workStartHour = 8
    var workStartMinute = 0

    var workEndHour = 18
    var workEndMinute = 0

    var isLoading = false
    var isSaving = false
    var errorMessage = ""
    var successMessage = ""

    func loadSettings() {
        isLoading = true
        errorMessage = ""

        FirestoreService.shared.fetchSystemSettings { result in
            DispatchQueue.main.async {
                self.isLoading = false

                switch result {
                case .success(let settings):
                    self.workStartHour = settings.workStartHour
                    self.workStartMinute = settings.workStartMinute
                    self.workEndHour = settings.workEndHour
                    self.workEndMinute = settings.workEndMinute

                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func saveSettings(adminUsername: String) {
        errorMessage = ""
        successMessage = ""

        // PIN validation (само ако е въведен)
        if !systemPin.isEmpty {
            guard systemPin.allSatisfy({ $0.isNumber }) else {
                errorMessage = "PIN must contain only digits."
                return
            }

            guard systemPin.count >= 4 else {
                errorMessage = "PIN must be at least 4 digits."
                return
            }
        }

        isSaving = true

        FirestoreService.shared.updateSystemSettings(
            systemPin: systemPin.isEmpty ? nil : systemPin,
            workStartHour: workStartHour,
            workStartMinute: workStartMinute,
            workEndHour: workEndHour,
            workEndMinute: workEndMinute,
            updatedBy: adminUsername
        ) { result in
            DispatchQueue.main.async {
                self.isSaving = false

                switch result {
                case .success:
                    self.successMessage = "Settings updated"
                    self.systemPin = ""

                    FirestoreService.shared.addEventLog(
                        type: EventLogType.updateSystemSettings.rawValue,
                        message: "\(adminUsername) updated system settings",
                        performedByUsername: adminUsername
                    ) { _ in }

                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
