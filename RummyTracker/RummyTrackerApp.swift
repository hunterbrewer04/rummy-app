import SwiftUI
import SwiftData

/// App entry point. Wires up the SwiftData store that persists games and hands
/// to disk, and shows the games list as the root screen.
@main
struct RummyTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            GamesListView()
        }
        // One container for the whole app; SwiftData manages saving/loading.
        .modelContainer(for: [Game.self, Hand.self])
    }
}
