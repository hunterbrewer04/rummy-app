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

    /// `1`, `2`, or `nil` if the game is still going.
    var winningPlayer: Int? {
        ScoringEngine.winner(
            player1Total: player1Total,
            player2Total: player2Total,
            target: targetScore
        )
    }

    var isFinished: Bool {
        winningPlayer != nil
    }

    var winnerName: String? {
        switch winningPlayer {
        case 1: return player1Name
        case 2: return player2Name
        default: return nil
        }
    }
}
