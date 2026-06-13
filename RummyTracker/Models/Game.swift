import Foundation
import SwiftData

/// A single game of rummy between two named players, played over many hands
/// until someone reaches the target score.
@Model
final class Game {
    var player1Name: String
    var player2Name: String
    var targetScore: Int
    var createdAt: Date

    /// Hands belonging to this game. Deleting the game deletes its hands.
    @Relationship(deleteRule: .cascade, inverse: \Hand.game)
    var hands: [Hand]

    /// Snapshotted once the game is first decided. Durable across later edits.
    var recordedWinnerName: String?
    var finishedAt: Date?

    init(
        player1Name: String,
        player2Name: String,
        targetScore: Int = 500,
        createdAt: Date = .now
    ) {
        self.player1Name = player1Name
        self.player2Name = player2Name
        self.targetScore = targetScore
        self.createdAt = createdAt
        self.hands = []
        self.recordedWinnerName = nil
        self.finishedAt = nil
    }
}

// MARK: - Derived scoring values
// These read from `hands` and delegate the actual rules to `ScoringEngine`,
// so the view layer never does scoring math itself.
extension Game {
    /// Hands in play order. Ties on `index` fall back to creation time so the
    /// order is always stable.
    var orderedHands: [Hand] {
        hands.sorted {
            $0.index != $1.index ? $0.index < $1.index : $0.createdAt < $1.createdAt
        }
    }

    /// The index to give the next hand. Lives on the model so every place that
    /// adds a hand uses the same rule.
    var nextHandIndex: Int {
        (hands.map(\.index).max() ?? 0) + 1
    }

    var player1Total: Int {
        ScoringEngine.total(of: hands.map(\.player1Score))
    }

    var player2Total: Int {
        ScoringEngine.total(of: hands.map(\.player2Score))
    }

    /// Live leader (1/2/nil) from current totals — used for UI highlight.
    var winningPlayerLive: Int? {
        ScoringEngine.winner(player1Total: player1Total, player2Total: player2Total, target: targetScore)
    }

    var isFinished: Bool { finishedAt != nil }
    var winnerName: String? { recordedWinnerName }

    /// Records the winner the first time the game is decided. Idempotent.
    func finalizeIfNeeded(now: Date = .now) {
        guard finishedAt == nil else { return }
        guard let name = ScoringEngine.decidedWinnerName(
            player1Name: player1Name, player2Name: player2Name,
            player1Total: player1Total, player2Total: player2Total, target: targetScore) else { return }
        recordedWinnerName = name
        finishedAt = now
    }

    /// Lets the user re-open a game to correct a mistake.
    func reopen() {
        recordedWinnerName = nil
        finishedAt = nil
    }
}
