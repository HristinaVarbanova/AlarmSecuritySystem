import SwiftUI

struct UserManagementView: View {
    let adminUser: FirebaseUser
    @State private var viewModel = UserManagementViewModel()

    var body: some View {
        ZStack {
            backgroundGradient

            VStack(spacing: 16) {
                header

                if viewModel.isLoading {
                    ProgressView("Loading users...")
                        .padding(.top, 40)
                } else if viewModel.users.isEmpty {
                    Text("No users found.")
                        .foregroundStyle(.secondary)
                        .padding(.top, 40)
                } else {
                    ScrollView {
                        VStack(spacing: 14) {
                            ForEach(viewModel.users, id: \.id) { user in
                                if user.id != adminUser.id {
                                    UserManagementCard(
                                        user: user,
                                        onApprove: {
                                            viewModel.updateUser(
                                                userId: user.id,
                                                isApproved: true,
                                                isBlocked: user.isBlocked,
                                                actionType: "APPROVE_USER",
                                                adminUsername: adminUser.username
                                            )
                                        },
                                        onBlock: {
                                            viewModel.updateUser(
                                                userId: user.id,
                                                isApproved: user.isApproved,
                                                isBlocked: true,
                                                actionType: "BLOCK_USER",
                                                adminUsername: adminUser.username
                                            )
                                        },
                                        onUnblock: {
                                            viewModel.updateUser(
                                                userId: user.id,
                                                isApproved: user.isApproved,
                                                isBlocked: false,
                                                actionType: "UNBLOCK_USER",
                                                adminUsername: adminUser.username
                                            )
                                        }
                                    )
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }

                Spacer()
            }
            .padding(22)
        }
        .navigationTitle("User Management")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadUsers()
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 46))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.blue, Color.yellow],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("User Management")
                .font(.largeTitle)
                .bold()

            Text("Approve, block and manage users")
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, 8)
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color.white,
                Color.blue.opacity(0.10),
                Color.yellow.opacity(0.08)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

}

struct UserManagementCard: View {
    let user: FirebaseUser
    let onApprove: () -> Void
    let onBlock: () -> Void
    let onUnblock: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                Image(systemName: user.role == "admin" ? "person.crop.circle.badge.checkmark" : "person.fill")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.blue, Color.yellow],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 46, height: 46)
                    .background(Color.white.opacity(0.85))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(user.username)
                        .font(.headline)

                    Text(user.email)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("Role: \(user.role)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            HStack(spacing: 8) {
                statusBadge(
                    text: user.isApproved ? "Approved" : "Pending",
                    isPositive: user.isApproved
                )

                statusBadge(
                    text: user.isBlocked ? "Blocked" : "Active",
                    isPositive: !user.isBlocked
                )
            }

            HStack(spacing: 10) {
                if !user.isApproved {
                    Button("Approve") {
                        onApprove()
                    }
                    .buttonStyle(AdminSmallButtonStyle(colors: [Color.blue, Color.yellow]))
                }

                if user.isBlocked {
                    Button("Unblock") {
                        onUnblock()
                    }
                    .buttonStyle(AdminSmallButtonStyle(colors: [Color.blue, Color.yellow]))
                } else {
                    Button("Block") {
                        onBlock()
                    }
                    .buttonStyle(AdminSmallButtonStyle(colors: [Color.red.opacity(0.85), Color.orange]))
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.45), lineWidth: 1)
        )
        .shadow(color: .blue.opacity(0.10), radius: 14, x: 0, y: 8)
    }

    private func statusBadge(text: String, isPositive: Bool) -> some View {
        Text(text)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(isPositive ? .green : .orange)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background((isPositive ? Color.green : Color.orange).opacity(0.12))
            .clipShape(Capsule())
    }
}

struct AdminSmallButtonStyle: ButtonStyle {
    let colors: [Color]

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                LinearGradient(
                    colors: colors,
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}   
