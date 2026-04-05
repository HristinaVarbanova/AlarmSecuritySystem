import SwiftUI
import SwiftData

struct DatabaseTestView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [AppUser]

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Button("Add Test User") {
                    let user = AppUser(
                        username: "user\(users.count + 1)",
                        password: "1234",
                        role: .user
                    )
                    modelContext.insert(user)
                }
                Button("Add Admin") {
                    let admin = AppUser(
                        username: "admin\(users.count + 1)",
                        password: "1234",
                        role: .admin
                    )
                    admin.isApproved = true
                    modelContext.insert(admin)
                }

                List(users) { user in
                    VStack(alignment: .leading) {
                        Text(user.username)
                            .font(.headline)
                        Text("Role: \(user.role.rawValue)")
                            .foregroundStyle(.secondary)
                        Text("Approved: \(user.isApproved ? "Yes" : "No")")
                            .foregroundStyle(.secondary)

                        Text("Blocked: \(user.isBlocked ? "Yes" : "No")")
                            .foregroundStyle(.secondary)
                    }
                
                }
            }
            .padding()
            .navigationTitle("Database Test")
        }
    }
}

#Preview {
    DatabaseTestView()
}
