import SwiftUI

struct ContentView: View {
    @State private var authViewModel = AuthViewModel()

    var body: some View {
        if authViewModel.currentUserId != nil {
            DatabaseTestView()
        } else {
            AnimatedAuthView(viewModel: authViewModel)
        }
    }
}

#Preview {
    ContentView()
}
