import SwiftUI

struct SystemSettingsView: View {
    let adminUser: FirebaseUser

    @State private var viewModel = SystemSettingsViewModel()

    var body: some View {
        ZStack {
            backgroundGradient

            ScrollView {
                VStack(spacing: 22) {
                    header

                    if viewModel.isLoading {
                        ProgressView("Loading settings...")
                            .padding(.top, 40)
                    } else {
                        settingsForm
                    }

                    Spacer()
                }
                .padding(24)
            }
        }
        .navigationTitle("System Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadSettings()
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 50))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.blue, Color.yellow],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("System Settings")
                .font(.largeTitle)
                .bold()

            Text("Change PIN and working hours")
                .foregroundStyle(.secondary)
        }
    }

    private var settingsForm: some View {
        VStack(spacing: 16) {
            SettingsTextField(
                title: "New PIN (leave empty to keep current)",
                value: $viewModel.systemPin,
                icon: "key.fill",
                keyboardType: .numberPad
            )

            timeSettingsCard

            if !viewModel.errorMessage.isEmpty {
                Text(viewModel.errorMessage)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            if !viewModel.successMessage.isEmpty {
                Text(viewModel.successMessage)
                    .foregroundStyle(.green)
                    .multilineTextAlignment(.center)
            }

            Button {
                viewModel.saveSettings(adminUsername: adminUser.username)
            } label: {
                Text(viewModel.isSaving ? "Saving..." : "Save Settings")
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
            .disabled(viewModel.isSaving)
        }
    }

    private var timeSettingsCard: some View {
        VStack(spacing: 18) {
            VStack(spacing: 10) {
                HStack {
                    Text("Work starts")
                        .font(.headline)

                    Spacer()

                    Text(String(format: "%02d:%02d", viewModel.workStartHour, viewModel.workStartMinute))
                        .font(.headline)
                        .fontWeight(.bold)
                }

                HStack {
                    Stepper("Hour", value: $viewModel.workStartHour, in: 0...23)
                    Stepper("Min", value: $viewModel.workStartMinute, in: 0...59)
                }
            }

            Divider()

            VStack(spacing: 10) {
                HStack {
                    Text("Work ends")
                        .font(.headline)

                    Spacer()

                    Text(String(format: "%02d:%02d", viewModel.workEndHour, viewModel.workEndMinute))
                        .font(.headline)
                        .fontWeight(.bold)
                }

                HStack {
                    Stepper("Hour", value: $viewModel.workEndHour, in: 0...23)
                    Stepper("Min", value: $viewModel.workEndMinute, in: 0...59)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
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
