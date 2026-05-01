import SwiftUI

struct SystemStatusView: View {
    @State private var systemState: SystemState?
    @State private var errorMessage = ""
    @State private var isLoading = true

    var body: some View {
        ZStack {
            backgroundGradient

            VStack(spacing: 24) {
                header

                if isLoading {
                    ProgressView("Loading system status...")
                } else if let systemState {
                    statusCards(systemState)
                } else {
                    Text(errorMessage.isEmpty ? "No system data found." : errorMessage)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                Spacer()
            }
            .padding(24)
        }
        .navigationTitle("System Status")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadSystemState()
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "shield.fill")
                .font(.system(size: 50))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.blue, Color.yellow],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("System Status")
                .font(.largeTitle)
                .bold()

            Text("Current security state")
                .foregroundStyle(.secondary)
        }
    }

    private func statusCards(_ state: SystemState) -> some View {
        VStack(spacing: 16) {
            StatusInfoCard(
                title: "Alarm State",
                value: state.isArmed ? "Armed" : "Disarmed",
                icon: state.isArmed ? "shield.checkered" : "shield.slash",
                isPositive: state.isArmed
            )

            StatusInfoCard(
                title: "Door State",
                value: state.doorLocked ? "Locked" : "Unlocked",
                icon: state.doorLocked ? "lock.fill" : "lock.open.fill",
                isPositive: state.doorLocked
            )

            StatusInfoCard(
                title: "Last Changed By",
                value: state.lastChangedBy,
                icon: "person.fill",
                isPositive: true
            )

            StatusInfoCard(
                title: "Changed At",
                value: state.changedAt.formatted(date: .abbreviated, time: .shortened),
                icon: "clock.fill",
                isPositive: true
            )

            Button("Refresh") {
                loadSystemState()
            }
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
            .padding(.top, 10)
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

    private func loadSystemState() {
        isLoading = true
        errorMessage = ""

        FirestoreService.shared.fetchSystemStateModel { result in
            DispatchQueue.main.async {
                isLoading = false

                switch result {
                case .success(let state):
                    systemState = state
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

struct StatusInfoCard: View {
    let title: String
    let value: String
    let icon: String
    let isPositive: Bool

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
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

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.headline)
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
}
