import SwiftUI
import SwiftData

/// App entry point. Wires up the SwiftData store that persists games and hands
/// to disk, and shows the games list as the root screen.
@main
struct RummyTrackerApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Game.self, Hand.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        Self.backfillFinishedGames(in: container.mainContext)
    }

    var body: some Scene {
        WindowGroup { GamesListView() }
            .modelContainer(container)
    }

    /// One-time migration: games decided under the pre-durable build never had
    /// their winner snapshotted. Finalize any already-decided game so its result
    /// shows correctly. Runs ONCE — re-running every launch would re-lock games
    /// the user intentionally reopened.
    @MainActor
    private static func backfillFinishedGames(in context: ModelContext) {
        let flagKey = "didBackfillDurableWinnersV1"
        guard !UserDefaults.standard.bool(forKey: flagKey) else { return }
        guard let games = try? context.fetch(FetchDescriptor<Game>()) else { return }
        for game in games {
            game.finalizeIfNeeded(now: game.orderedHands.last?.createdAt ?? game.createdAt)
        }
        try? context.save()
        UserDefaults.standard.set(true, forKey: flagKey)
    }
}
