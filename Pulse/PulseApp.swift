import SwiftUI
import SwiftData

@main
struct PulseApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [WorkoutRecord.self, HRSample.self])
    }
}
