import Foundation

enum EventLogType: String {
    case userRegistered = "User registered"
    case userLogin = "User login"
    case userLogout = "User logout"

    case approveUser = "Approve user"
    case blockUser = "Block user"
    case unblockUser = "Unblock user"

    case arm = "Arm"
    case disarm = "Disarm"

    case updateSystemSettings = "Update system settings"

    case failedAccessAttempt = "Failed access attempt"
    case alarmTriggered = "Alarm triggered"
    case updateProfile = "Update profile"
}
