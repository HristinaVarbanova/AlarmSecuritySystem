import SwiftUI

struct QuickActionsView: View {
    let user: FirebaseUser

    @State private var isLoading = false
    @State private var message = ""
    @State private var showAlert = false

    var body: some View {
        ZStack {
            backgroundGradient

            VStack(spacing: 24) {
                header

                VStack(spacing: 18) {
                    actionButton(
                        title: "Arm System",
                        icon: "shield.fill",
                        colors: [Color.blue, Color.yellow]
                    ) {
                        armSystem()
                    }

                    actionButton(
                        title: "Disarm System",
                        icon: "shield.slash.fill",
                        colors: [Color.yellow, Color.blue]
                    ) {
                        disarmSystem()
                    }
                }

                if isLoading {
                    ProgressView("Sending command...")
                        .padding(.top)
                }

                Spacer()
            }
            .padding(24)
        }
        .navigationTitle("Quick Actions")
        .navigationBarTitleDisplayMode(.inline)
        .alert("System Message", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(message)
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 50))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.blue, Color.yellow],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("Quick Actions")
                .font(.largeTitle)
                .bold()

            Text("Control the security system")
                .foregroundStyle(.secondary)
        }
    }

    private func actionButton(
        title: String,
        icon: String,
        colors: [Color],
        action: @escaping () -> Void
    ) -> some View {
        Button {
            action()
        } label: {
            HStack {
                Image(systemName: icon)
                    .font(.title2)

                Text(title)
                    .font(.headline)

                Spacer()
            }
            .foregroundStyle(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: colors,
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .blue.opacity(0.18), radius: 12, x: 0, y: 8)
        }
        .disabled(isLoading)
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

    private func armSystem() {
        isLoading = true

        Task {
            do {
                try await ESP32Service.shared.armSystem()

                FirestoreService.shared.updateSystemState(
                    isArmed: true,
                    doorLocked: true,
                    changedBy: user.username
                ) { _ in }

                FirestoreService.shared.addEventLog(
                    type: "ARM",
                    message: "\(user.username) armed the system",
                    performedByUsername: user.username
                ) { _ in }

                await MainActor.run {
                    isLoading = false
                    message = "System armed successfully."
                    showAlert = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    message = "Failed to arm system: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }

    private func disarmSystem() {
        isLoading = true

        Task {
            do {
                try await ESP32Service.shared.disarmSystem()

                FirestoreService.shared.updateSystemState(
                    isArmed: false,
                    doorLocked: false,
                    changedBy: user.username
                ) { _ in }

                FirestoreService.shared.addEventLog(
                    type: "DISARM",
                    message: "\(user.username) disarmed the system",
                    performedByUsername: user.username
                ) { _ in }

                await MainActor.run {
                    isLoading = false
                    message = "System disarmed successfully."
                    showAlert = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    message = "Failed to disarm system: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
}
