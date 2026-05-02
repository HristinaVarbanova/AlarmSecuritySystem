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
            Text("User Dashboard")
                .font(.system(size: 32, weight: .bold))

            Text("Welcome, \(user.username)")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("Access and monitor your security system")
                .font(.subheadline)
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
