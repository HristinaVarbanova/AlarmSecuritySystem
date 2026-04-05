import SwiftUI
import SwiftData
import FirebaseCore

@main
struct AlarmSecuritySystemApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            AppUser.self,
            EventLog.self
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            DatabaseTestView()
        }
        .modelContainer(sharedModelContainer)
    }
}
