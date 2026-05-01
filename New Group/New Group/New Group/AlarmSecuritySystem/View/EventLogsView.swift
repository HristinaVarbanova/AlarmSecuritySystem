import SwiftUI

struct EventLogsView: View {
    @State private var logs: [FirebaseEventLog] = []
    @State private var isLoading = true
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            backgroundGradient

            VStack(spacing: 16) {
                header

                if isLoading {
                    ProgressView("Loading event logs...")
                        .padding(.top, 40)
                } else if logs.isEmpty {
                    Text("No event logs found.")
                        .foregroundStyle(.secondary)
                        .padding(.top, 40)
                } else {
                    ScrollView {
                        VStack(spacing: 14) {
                            ForEach(logs) { log in
                                EventLogCard(log: log)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .padding(22)
        }
        .navigationTitle("Event Logs")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadLogs()
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "list.bullet.clipboard.fill")
                .font(.system(size: 46))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.blue, Color.yellow],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("Event Logs")
                .font(.largeTitle)
                .bold()

            Text("System activity history")
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

    private func loadLogs() {
        isLoading = true
        errorMessage = ""

        FirestoreService.shared.fetchEventLogModels { result in
            DispatchQueue.main.async {
                isLoading = false

                switch result {
                case .success(let logs):
                    self.logs = logs
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}

struct EventLogCard: View {
    let log: FirebaseEventLog

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
                Text(log.type)
                    .font(.headline)

                Text(log.message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("By: \(log.performedByUsername)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(log.createdAt.formatted(date: .abbreviated, time: .shortened))
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

    private var iconName: String {
        switch log.type.uppercased() {
        case "LOGIN":
            return "person.fill.checkmark"
        case "SIGNUP":
            return "person.badge.plus"
        case "ARM":
            return "shield.fill"
        case "DISARM":
            return "shield.slash"
        case "ACCESS_DENIED":
            return "xmark.shield.fill"
        default:
            return "doc.text.fill"
        }
    }
}
