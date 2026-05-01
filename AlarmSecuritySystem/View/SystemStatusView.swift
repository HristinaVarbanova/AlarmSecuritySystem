import SwiftUI

struct SystemStatusView: View {
    @State private var viewModel = SystemStatusViewModel()

    var body: some View {
        ZStack {
            backgroundGradient

            VStack(spacing: 24) {
                header

                if viewModel.isLoading {
                    ProgressView("Loading system status...")
                } else if let systemState = viewModel.systemState {
                    statusCards(systemState)
                } else {
                    Text(viewModel.errorMessage.isEmpty ? "No system data found." : viewModel.errorMessage)
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
            viewModel.loadSystemState()
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
                viewModel.loadSystemState()
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
}
