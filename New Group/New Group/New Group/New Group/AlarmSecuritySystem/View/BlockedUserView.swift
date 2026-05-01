import SwiftUI

struct BlockedUserView: View {
    let viewModel: AuthViewModel

    var body: some View {
        VStack(spacing: 20) {
            Text("Account Blocked")
                .font(.title)
                .bold()

            Text("Your account has been blocked by an administrator.")

            Button("Logout") {
                viewModel.logout()
            }
            .padding()
        }
        .padding()
    }
}
