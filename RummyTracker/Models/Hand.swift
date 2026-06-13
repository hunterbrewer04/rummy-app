import Foundation
import SwiftData

/// One hand within a game: the points each player earned that hand.
/// Scores may be negative.
@Model
final class Hand {
    /// Position within the game, used purely for stable ordering.
    var index: Int
    var player1Score: Int
    var player2Score: Int
    var createdAt: Date

    /// The game this hand belongs to (inverse of `Game.hands`).
    var game: Game?

    init(
        index: Int,
        player1Score: Int,
        player2Score: Int,
        createdAt: Date = .now,
        game: Game? = nil
    ) {
        self.index = index
        self.player1Score = player1Score
        self.player2Score = player2Score
        self.createdAt = createdAt
        self.game = game
    }
}
