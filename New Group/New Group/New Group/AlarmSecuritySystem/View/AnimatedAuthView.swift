import SwiftUI

struct AnimatedAuthView: View {
    enum Mode {
        case login
        case signup
    }

    let viewModel: AuthViewModel

    @State private var mode: Mode = .login

    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    @State private var isSubmitting = false
    @FocusState private var focusedField: Field?

    @State private var animateLock = false
    @State private var shakeTrigger: CGFloat = 0
    @State private var showError = false
    @State private var errorMessage = ""

    enum Field {
        case username
        case email
        case password
        case confirmPassword
    }

    private var isTyping: Bool {
        focusedField != nil
    }

    private var isFormReady: Bool {
        switch mode {
        case .login:
            return !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                   !password.isEmpty

        case .signup:
            return !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                   !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                   !password.isEmpty &&
                   !confirmPassword.isEmpty
        }
    }

    private var passwordsMatch: Bool {
        password == confirmPassword
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.white,
                    Color.blue.opacity(0.10),
                    Color.yellow.opacity(0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 22) {
                Spacer(minLength: 20)

                animatedLock

                VStack(spacing: 6) {
                    Text(mode == .login ? "Welcome Back" : "Create Account")
                        .font(.system(size: 30, weight: .bold))

                    Text(mode == .login
                         ? "Log in to access your security system"
                         : "Sign up to request access")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                authCard
                    .modifier(ShakeEffect(animatableData: shakeTrigger))

                modeSwitcher

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: mode)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isFormReady)
        .onChange(of: focusedField) { _, newValue in
            animateLock = newValue != nil
        }
        .alert("Attention", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    private var animatedLock: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.8))
                .frame(width: 130, height: 130)
                .shadow(color: .blue.opacity(0.12), radius: 20, x: 0, y: 10)

            Circle()
                .stroke(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.7), Color.yellow.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
                .frame(width: 130, height: 130)
                .scaleEffect(animateLock ? 1.06 : 1.0)
                .opacity(animateLock ? 1.0 : 0.6)
                .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: animateLock)

            Image(systemName: isFormReady ? "lock.open.fill" : "lock.fill")
                .font(.system(size: 48, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.blue, Color.yellow],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .scaleEffect(isTyping ? 1.08 : 1.0)
                .rotationEffect(.degrees(isTyping ? 3 : 0))
        }
        .frame(height: 150)
    }

    private var authCard: some View {
        VStack(spacing: 16) {
            if mode == .signup {
                AuthTextField(
                    title: "Username",
                    systemImage: "person.fill",
                    text: $username
                )
                .focused($focusedField, equals: .username)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            AuthTextField(
                title: "Email",
                systemImage: "envelope.fill",
                text: $email
            )
            .keyboardType(.emailAddress)
            .focused($focusedField, equals: .email)

            AuthSecureField(
                title: "Password",
                systemImage: "lock.fill",
                text: $password
            )
            .focused($focusedField, equals: .password)

            if mode == .signup {
                AuthSecureField(
                    title: "Confirm Password",
                    systemImage: "checkmark.shield.fill",
                    text: $confirmPassword
                )
                .focused($focusedField, equals: .confirmPassword)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            if mode == .signup && !confirmPassword.isEmpty && !passwordsMatch {
                Text("Passwords do not match")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.opacity)
            }

            AnimatedPrimaryButton(
                title: isSubmitting
                    ? "Please wait..."
                    : (mode == .login ? "Log In" : "Sign Up"),
                isEnabled: isFormReady && !isSubmitting
            ) {
                submit()
            }
            .padding(.top, 4)
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.45), lineWidth: 1)
        )
        .shadow(color: .blue.opacity(0.12), radius: 22, x: 0, y: 14)
    }

    private var modeSwitcher: some View {
        HStack(spacing: 6) {
            Text(mode == .login ? "Don't have an account?" : "Already have an account?")
                .foregroundStyle(.secondary)

            Button(mode == .login ? "Sign Up" : "Log In") {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    mode = mode == .login ? .signup : .login
                    username = ""
                    email = ""
                    password = ""
                    confirmPassword = ""
                    focusedField = nil
                }
            }
            .fontWeight(.semibold)
            .foregroundStyle(.blue)
        }
        .font(.footnote)
    }

    private func submit() {
        focusedField = nil

        switch mode {
        case .login:
            guard isFormReady else {
                triggerError("Please enter email and password.")
                return
            }

            isSubmitting = true

            Task {
                let success = await viewModel.login(
                    email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                    password: password
                )

                await MainActor.run {
                    isSubmitting = false

                    if !success {
                        triggerError(viewModel.errorMessage)
                    }
                }
            }

        case .signup:
            guard isFormReady else {
                triggerError("Please fill all fields.")
                return
            }

            guard passwordsMatch else {
                triggerError("Passwords do not match.")
                return
            }

            isSubmitting = true

            Task {
                let success = await viewModel.signUp(
                    username: username.trimmingCharacters(in: .whitespacesAndNewlines),
                    email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                    password: password
                )

                await MainActor.run {
                    isSubmitting = false

                    if !success {
                        triggerError(viewModel.errorMessage)
                    }
                }
            }
        }
    }

    private func triggerError(_ message: String) {
        errorMessage = message.isEmpty ? "Something went wrong." : message
        showError = true

        withAnimation(.easeInOut(duration: 0.08)) {
            shakeTrigger += 1
        }
    }
}

struct AuthTextField: View {
    let title: String
    let systemImage: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(.blue)

            TextField(title, text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct AuthSecureField: View {
    let title: String
    let systemImage: String
    @Binding var text: String
    @State private var isSecure = true

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(.blue)

            Group {
                if isSecure {
                    SecureField(title, text: $text)
                } else {
                    TextField(title, text: $text)
                }
            }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()

            Button {
                isSecure.toggle()
            } label: {
                Image(systemName: isSecure ? "eye.slash.fill" : "eye.fill")
                    .foregroundStyle(.yellow.opacity(0.9))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct AnimatedPrimaryButton: View {
    let title: String
    let isEnabled: Bool
    let action: () -> Void

    @State private var pressed = false

    var body: some View {
        Button {
            action()
        } label: {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: isEnabled
                        ? [Color.blue, Color.yellow.opacity(0.95)]
                        : [Color.gray.opacity(0.5), Color.gray.opacity(0.4)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .scaleEffect(pressed ? 0.97 : 1.0)
                .shadow(color: isEnabled ? .blue.opacity(0.2) : .clear, radius: 10, x: 0, y: 6)
        }
        .disabled(!isEnabled)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.12)) {
                        pressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.12)) {
                        pressed = false
                    }
                }
        )
    }
}

struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit: CGFloat = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(
            CGAffineTransform(
                translationX: amount * sin(animatableData * .pi * shakesPerUnit),
                y: 0
            )
        )
    }
}

#Preview {
    AnimatedAuthView(viewModel: AuthViewModel())
}
