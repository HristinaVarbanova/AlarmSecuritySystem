import SwiftUI
import FirebaseFirestore

struct DatabaseTestView: View {
    @State private var statusText = "Loading..."
    @State private var logsCount = 0
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Firebase Test")
                .font(.largeTitle)
                .bold()
            
            Text("System State:")
                .font(.headline)
            
            Text(statusText)
                .multilineTextAlignment(.center)
            
            Text("Logs count: \(logsCount)")
                .font(.headline)
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
            
            Button("Reload Data") {
                loadData()
            }
            .padding()
        }
        .padding()
        .onAppear {
            loadData()
        }
    }
    
    private func loadData() {
        errorMessage = ""
        
        FirestoreService.shared.fetchSystemState { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    let isArmed = data["isArmed"] as? Bool ?? false
                    let doorLocked = data["doorLocked"] as? Bool ?? false
                    let changedAtTimestamp = data["changedAt"] as? Timestamp
                    let changedAt = changedAtTimestamp?.dateValue().formatted(date: .abbreviated, time: .shortened) ?? "Unknown"
                    let lastChangedBy = data["lastChangedBy"] as? String ?? "Unknown"
                    
                    statusText = """
                    Armed: \(isArmed ? "Yes" : "No")
                    Door locked: \(doorLocked ? "Yes" : "No")
                    Changed at: \(changedAt)
                    Last changed by: \(lastChangedBy)
                    """
                case .failure(let error):
                    errorMessage = "System state error: \(error.localizedDescription)"
                }
            }
        }
        
        FirestoreService.shared.fetchEventLogs { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let logs):
                    logsCount = logs.count
                case .failure(let error):
                    errorMessage = "Logs error: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    DatabaseTestView()
}
