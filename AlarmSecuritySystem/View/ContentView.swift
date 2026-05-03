import SwiftUI

struct ContentView: View {
    @State private var authViewModel = AuthViewModel()

    var body: some View {
        Group {
            if authViewModel.currentUserId == nil {
                AnimatedAuthView(viewModel: authViewModel)
            } else if let user = authViewModel.currentUser {
                if !user.isApproved {
                    PendingApprovalView(viewModel: authViewModel)
                } else if user.role == "admin" {
                    AdminDashboardView(user: user, viewModel: authViewModel)
                } else {
                    UserDashboardView(user: user, viewModel: authViewModel)
                }
            } else {
                ProgressView("Loading user data...")
            }
        }
    }
}

#Preview {
    ContentView()
}
