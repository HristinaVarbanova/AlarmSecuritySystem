import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [AppUser]

    @State private var viewModel = AuthViewModel()

    var body: some View {
        Group {
            if let user = viewModel.loggedInUser {
                DashboardView(user: user, viewModel: viewModel)
            } else {
                AnimatedAuthView(
                    viewModel: viewModel,
                    users: users,
                    modelContext: modelContext
                )
            }
        }
        .onAppear {
            seedUsersIfNeeded()
        }
    }

    private func seedUsersIfNeeded() {
        if users.isEmpty {
            let admin = AppUser(username: "admin", password: "1234", role: .admin)
            let child = AppUser(username: "child", password: "1111", role: .user)

            modelContext.insert(admin)
            modelContext.insert(child)
        }
    }
}

#Preview {
    ContentView()
}
