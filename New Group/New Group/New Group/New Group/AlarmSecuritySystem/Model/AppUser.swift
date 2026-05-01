import Foundation
import SwiftData

@Model
final class AppUser {
    var username: String
    var password: String
    var roleRawValue: String
    var isActive: Bool
    var isBlocked: Bool
    var isApproved: Bool

    init(username: String, password: String, role: UserRole) {
        self.username = username
        self.password = password
        self.roleRawValue = role.rawValue
        self.isActive = true
        self.isBlocked = false
        self.isApproved = false
    }

    var role: UserRole {
        get { UserRole(rawValue: roleRawValue) ?? .user }
        set { roleRawValue = newValue.rawValue }
    }
}
