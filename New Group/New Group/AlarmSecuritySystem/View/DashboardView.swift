import SwiftUI

struct DashboardView: View {
    let user: AppUser
    var viewModel: AuthViewModel

    var body: some View {
        VStack(spacing: 30) {
            Text("Welcome \(user.username)")
                .font(.largeTitle)

            Text("Role: \(user.role.rawValue)")

            Button("ARM SYSTEM") {
                print("ARM")
            }
            .buttonStyle(.borderedProminent)

            Button("DISARM SYSTEM") {
                print("DISARM")
            }
            .buttonStyle(.borderedProminent)

            if user.role == .admin {
                Button("Change Password") {
                    print("Admin changing password")
                }
            } else {
                Text("You cannot change the password")
                    .foregroundColor(.red)
            }

            Button("Logout") {
                viewModel.logout()
            }
        }
        .padding()
    }
}
