import SwiftUI

struct NotificationsView: View {
    let user: FirebaseUser

    @State private var viewModel = NotificationsViewModel()

    var body: some View {
        ZStack {
            backgroundGradient

            VStack(spacing: 16) {
                header

                if viewModel.isLoading {
                    ProgressView("Loading notifications...")
                        .padding(.top, 40)
                } else if viewModel.notifications.isEmpty {
                    Text("No notifications found.")
                        .foregroundStyle(.secondary)
                        .padding(.top, 40)
                } else {
                    ScrollView {
                        VStack(spacing: 14) {
                            ForEach(viewModel.notifications) { notification in
                                NotificationCard(notification: notification)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }

                Spacer()
            }
            .padding(22)
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.startListening(for: user.id)
        }
        .onDisappear {
            viewModel.stopListening()
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 46))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.blue, Color.yellow],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("Notifications")
                .font(.largeTitle)
                .bold()

            Text("Personal security alerts")
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

struct NotificationCard: View {
    let notification: AppNotification

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: iconName)
                .font(.title3)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.blue, Color.yellow],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 44, height: 44)
                .background(Color.white.opacity(0.85))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 6) {
                Text(titleText)
                    .font(.headline)

                Text(notification.message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(notification.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()
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

    private var titleText: String {
        switch notification.type {
        case "SYSTEM_ARMED":
            return "System Armed"
        case "SYSTEM_DISARMED":
            return "System Disarmed"
        case "ACCESS_DENIED_CARD":
            return "Access Denied"
        case "ACCESS_DENIED_OUTSIDE_HOURS":
            return "Outside Working Hours"
        case "USER_BLOCKED":
            return "Account Blocked"
        case "USER_UNBLOCKED":
            return "Account Unblocked"
        default:
            return "Notification"
        }
    }

    private var iconName: String {
        switch notification.type {
        case "SYSTEM_ARMED":
            return "shield.fill"
        case "SYSTEM_DISARMED":
            return "shield.slash.fill"
        case "ACCESS_DENIED_CARD":
            return "xmark.shield.fill"
        case "ACCESS_DENIED_OUTSIDE_HOURS":
            return "clock.badge.exclamationmark"
        case "USER_BLOCKED":
            return "person.crop.circle.badge.xmark"
        case "USER_UNBLOCKED":
            return "person.crop.circle.badge.checkmark"
        default:
            return "bell.fill"
        }
    }
}
