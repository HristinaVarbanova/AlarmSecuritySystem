import SwiftUI

struct AdminDashboardView: View {
    let user: FirebaseUser
    let viewModel: AuthViewModel
    @State private var dashboardViewModel = DashboardViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        header

                        DashboardSectionTitle(title: "System Overview")

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            NavigationLink {
                                SystemStatusView()
                            } label: {
                                DashboardCard(
                                    title: "System Status",
                                    subtitle: dashboardViewModel.systemStatusText,
                                    icon: "shield.fill",
                                    color: .blue
                                )
                            }
                            .buttonStyle(.plain)

                            DashboardCard(
                                title: "Live Camera",
                                subtitle: "ESP32-CAM stream",
                                icon: "video.fill",
                                color: .blue
                            )

                            NavigationLink {
                                QuickActionsView(user: user)
                            } label: {
                                DashboardCard(
                                    title: "Quick Actions",
                                    subtitle: "Arm / Disarm",
                                    icon: "bolt.fill",
                                    color: .blue
                                )
                            }
                            .buttonStyle(.plain)

                            NavigationLink {
                                EventLogsView()
                            } label: {
                                DashboardCard(
                                    title: "Event Logs",
                                    subtitle: "Activity history",
                                    icon: "list.bullet.clipboard.fill",
                                    color: .blue
                                )
                            }
                            .buttonStyle(.plain)

                            NavigationLink {
                                UserManagementView()
                            } label: {
                                DashboardCard(
                                    title: "User Management",
                                    subtitle: "Approve / block users",
                                    icon: "person.3.fill",
                                    color: .blue
                                )
                            }
                            .buttonStyle(.plain)

                            DashboardCard(
                                title: "System Settings",
                                subtitle: "PIN, cards and rules",
                                icon: "gearshape.fill",
                                color: .blue
                            )

                            DashboardCard(
                                title: "Notifications",
                                subtitle: "Security alerts",
                                icon: "bell.badge.fill",
                                color: .blue
                            )

                            DashboardCard(
                                title: "Profile",
                                subtitle: "Admin account",
                                icon: "person.crop.circle.fill",
                                color: .blue
                            )
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
        .navigationBarHidden(true)
        .onAppear {
            dashboardViewModel.loadSystemState()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Admin Dashboard")
                .font(.system(size: 32, weight: .bold))

            Text("Welcome, \(user.username)")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("Full system control and monitoring")
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
