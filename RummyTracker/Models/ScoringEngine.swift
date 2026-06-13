import Foundation

/// All the scoring rules in one place, with no dependency on SwiftUI or
/// SwiftData so the logic can be unit-tested in isolation. If the rules ever
/// change (different target, "must win by 2", etc.), this is the only file to
/// touch.
enum ScoringEngine {

    /// Running total for a player: the sum of their per-hand scores.
    /// Scores may be negative, so this can go down as well as up.
    static func total(of scores: [Int]) -> Int {
        scores.reduce(0, +)
    }

    /// Decides the winner given both running totals and the target score.
    ///
    /// - Returns: `1` if player one has won, `2` if player two has won, or
    ///   `nil` if the game should continue.
    ///
    /// Rules:
    /// - Nobody has reached the target yet → no winner (`nil`).
    /// - Exactly one player is at/over the target → that player wins.
    /// - Both are at/over the target → the higher total wins. An exact tie is
    ///   undecided, so they play another hand (`nil`).
    static func winner(player1Total: Int, player2Total: Int, target: Int) -> Int? {
        let p1Reached = player1Total >= target
        let p2Reached = player2Total >= target

        switch (p1Reached, p2Reached) {
        case (false, false):
            return nil
        case (true, false):
            return 1
        case (false, true):
            return 2
        case (true, true):
            if player1Total > player2Total { return 1 }
            if player2Total > player1Total { return 2 }
            return nil
        }
    }
}
