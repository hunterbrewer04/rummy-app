import Testing
import SwiftData
@testable import RummyTracker

@MainActor
struct GameFinalizeTests {
    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Game.self, Hand.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        return ModelContext(container)
    }

    @Test func finalizeRecordsWinnerOnceAndIsDurable() throws {
        let ctx = try makeContext()
        let game = Game(player1Name: "A", player2Name: "B", targetScore: 500)
        ctx.insert(game)
        let h1 = Hand(index: 1, player1Score: 510, player2Score: 100); h1.game = game; ctx.insert(h1)

        game.finalizeIfNeeded()
        #expect(game.isFinished)
        #expect(game.winnerName == "A")

        // A later edit that drops A below target must NOT erase the recorded win.
        h1.player1Score = 100
        game.finalizeIfNeeded()
        #expect(game.winnerName == "A")

        game.reopen()
        #expect(!game.isFinished)
        #expect(game.winnerName == nil)
    }

    @Test func reopenThenFinalizeRecordsAgain() throws {
        let ctx = try makeContext()
        let game = Game(player1Name: "A", player2Name: "B", targetScore: 500)
        ctx.insert(game)
        let h1 = Hand(index: 1, player1Score: 510, player2Score: 100); h1.game = game; ctx.insert(h1)

        game.finalizeIfNeeded()
        #expect(game.isFinished)
        #expect(game.winnerName == "A")

        game.reopen()
        #expect(!game.isFinished)
        #expect(game.winnerName == nil)

        // Re-finalizing a still-decided game records the winner again.
        game.finalizeIfNeeded()
        #expect(game.isFinished)
        #expect(game.winnerName == "A")
    }

    @Test func undoStyleReinsertRefinalizes() throws {
        let ctx = try makeContext()
        let game = Game(player1Name: "A", player2Name: "B", targetScore: 500)
        ctx.insert(game)
        let winning = Hand(index: 1, player1Score: 510, player2Score: 100)
        winning.game = game; ctx.insert(winning)

        game.finalizeIfNeeded()
        #expect(game.isFinished)
        #expect(game.winnerName == "A")

        // Deleting the winning hand keeps the result via the snapshot.
        ctx.delete(winning)
        #expect(game.isFinished)
        #expect(game.winnerName == "A")

        // Reopen, then re-insert (undo path) and re-finalize: it finalizes again.
        game.reopen()
        #expect(!game.isFinished)
        let reinserted = Hand(index: 1, player1Score: 510, player2Score: 100)
        reinserted.game = game; ctx.insert(reinserted)
        game.finalizeIfNeeded()
        #expect(game.isFinished)
        #expect(game.winnerName == "A")
    }
}
