import SwiftUI

struct PendingApprovalView: View {
    let viewModel: AuthViewModel

    var body: some View {
        VStack(spacing: 20) {
            Text("Account Pending Approval")
                .font(.title)
                .bold()

            Text("Your account is waiting for admin approval.")

            Button("Logout") {
                viewModel.logout()
            }
            .padding()
        }
        .padding()
    }
}

