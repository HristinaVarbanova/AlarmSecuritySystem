import SwiftUI

struct UserDashboardView: View {
    let user: FirebaseUser
    let viewModel: AuthViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        header

                        if user.isBlocked {
                            Text("Your account is blocked. Only notifications are available.")
                                .font(.subheadline)
                                .foregroundStyle(.red)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.10))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }

                        DashboardSectionTitle(title: "My Security Access")

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            NavigationLink {
                                SystemStatusView()
                            } label: {
                                DashboardCard(
                                    title: "System Status",
                                    subtitle: "Current state",
                                    icon: "shield.fill",
                                    color: .blue
                                )
                            }
                            .buttonStyle(.plain)
                            .disabled(user.isBlocked)
                            .opacity(user.isBlocked ? 0.4 : 1)
                            
                            NavigationLink {
                                LiveCameraView()
                            } label: {
                                DashboardCard(
                                    title: "Live Camera",
                                    subtitle: "ESP32-CAM stream",
                                    icon: "video.fill",
                                    color: .blue
                                )
                            }
                            .buttonStyle(.plain)
                            .disabled(user.isBlocked)
                            .opacity(user.isBlocked ? 0.4 : 1)

                            NavigationLink {
                                QuickActionsView(user: user)
                            } label: {
                                DashboardCard(
                                    title: "Quick Actions",
                                    subtitle: "Access options",
                                    icon: "bolt.fill",
                                    color: .blue
                                )
                            }
                            .buttonStyle(.plain)
                            .disabled(user.isBlocked)
                            .opacity(user.isBlocked ? 0.4 : 1)
                            

                            NavigationLink {
                                ProfileView(user: user, viewModel: viewModel)
                            } label: {
                                DashboardCard(
                                    title: "Profile",
                                    subtitle: "Your account",
                                    icon: "person.crop.circle.fill",
                                    color: .blue
                                )
                            }
                            .buttonStyle(.plain)
                            .disabled(user.isBlocked)
                            .opacity(user.isBlocked ? 0.4 : 1)
                        }

                        Button {
                            viewModel.logout()
                        } label: {
                            Text("Logout")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [Color.blue, Color.yellow],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                        }
                        .padding(.top, 10)
                    }
                    .padding(22)
                }
            }
            .navigationBarHidden(true)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Welcome, \(user.username)")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
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
