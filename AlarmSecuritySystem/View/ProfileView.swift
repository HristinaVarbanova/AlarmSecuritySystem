import SwiftUI

struct ProfileView: View {
    let user: FirebaseUser
    let viewModel: AuthViewModel

    @State private var isEditing = false

    @State private var username: String
    @State private var email: String
    @State private var newPassword = ""

    @State private var isSaving = false
    @State private var showAlert = false
    @State private var alertMessage = ""

    init(user: FirebaseUser, viewModel: AuthViewModel) {
        self.user = user
        self.viewModel = viewModel
        _username = State(initialValue: user.username)
        _email = State(initialValue: user.email)
    }

    var body: some View {
        ZStack {
            backgroundGradient

            ScrollView {
                VStack(spacing: 22) {
                    header

                    if isEditing {
                        editSection
                    } else {
                        infoSection
                    }

                    Button {
                        if isEditing {
                            saveChanges()
                        } else {
                            isEditing = true
                        }
                    } label: {
                        Text(isEditing ? (isSaving ? "Saving..." : "Save Changes") : "Edit Profile")
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
                    .disabled(isSaving)

                    if isEditing {
                        Button {
                            username = user.username
                            email = user.email
                            newPassword = ""
                            isEditing = false
                        } label: {
                            Text("Cancel")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white.opacity(0.7))
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                        }
                    }

                    Button {
                        viewModel.logout()
                    } label: {
                        Text("Logout")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.85))
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                    }

                    Spacer()
                }
                .padding(24)
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Profile", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 58))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.blue, Color.yellow],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text(user.username)
                .font(.largeTitle)
                .bold()

            Text(user.email)
                .foregroundStyle(.secondary)
        }
    }

    private var infoSection: some View {
        VStack(spacing: 14) {
            ProfileInfoRow(title: "Username", value: user.username, icon: "person.fill")
            ProfileInfoRow(title: "Email", value: user.email, icon: "envelope.fill")
            ProfileInfoRow(title: "Role", value: user.role, icon: "shield.fill")

            if user.role != "admin" {
                ProfileInfoRow(
                    title: "Status",
                    value: user.isApproved ? "Approved" : "Pending",
                    icon: "checkmark.seal.fill"
                )

                ProfileInfoRow(
                    title: "Access",
                    value: user.isBlocked ? "Blocked" : "Active",
                    icon: "lock.fill"
                )
            }
        }
    }

    private var editSection: some View {
        VStack(spacing: 14) {
            editableField(title: "Username", text: $username, icon: "person.fill")
            editableField(title: "Email", text: $email, icon: "envelope.fill")
            secureEditableField(title: "New Password", text: $newPassword, icon: "lock.fill")
            ProfileInfoRow(title: "Role", value: user.role, icon: "shield.fill")
        }
    }

    private func editableField(title: String, text: Binding<String>, icon: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.blue, Color.yellow],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 42, height: 42)
                .background(Color.white.opacity(0.85))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextField(title, text: text)
                    .font(.headline)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func secureEditableField(title: String, text: Binding<String>, icon: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.blue, Color.yellow],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 42, height: 42)
                .background(Color.white.opacity(0.85))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                SecureField("Leave empty to keep current password", text: text)
                    .font(.headline)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

            Spacer()
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

    private func saveChanges() {
        isSaving = true

        Task {
            var success = true

            if username != user.username {
                success = await viewModel.updateUsername(newUsername: username)
            }

            if success && email != user.email {
                success = await viewModel.updateEmail(newEmail: email)
            }

            if success && !newPassword.isEmpty {
                success = await viewModel.updatePassword(newPassword: newPassword)
            }

            await MainActor.run {
                isSaving = false
                alertMessage = success ? "Profile updated successfully." : viewModel.errorMessage
                showAlert = true
                newPassword = ""

                if success {
                    isEditing = false
                }
            }
        }
    }
}
