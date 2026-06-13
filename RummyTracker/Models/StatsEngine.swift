import Foundation

/// A finished game reduced to plain values (no SwiftData), so stats are
/// pure and natively testable.
struct GameResult {
    let player1Name: String
    let player2Name: String
    let player1Total: Int
    let player2Total: Int
    let winnerName: String
}

struct PlayerStats {
    let name: String
    let gamesPlayed: Int
    let wins: Int
    let longestStreak: Int
    var losses: Int { gamesPlayed - wins }
    var winPercent: Int { gamesPlayed == 0 ? 0 : Int((Double(wins) / Double(gamesPlayed) * 100).rounded()) }
}

enum StatsEngine {
    /// One PlayerStats per distinct name appearing in the results, sorted by wins.
    static func standings(from results: [GameResult]) -> [PlayerStats] {
        var names: [String] = []
        for r in results { for n in [r.player1Name, r.player2Name] where !names.contains(n) { names.append(n) } }
        return names
            .map { PlayerStats(name: $0,
                               gamesPlayed: gamesPlayed(name: $0, in: results),
                               wins: wins(name: $0, in: results),
                               longestStreak: longestStreak(name: $0, in: results)) }
            .sorted { $0.wins > $1.wins }
    }

    static func gamesPlayed(name: String, in results: [GameResult]) -> Int {
        results.filter { $0.player1Name == name || $0.player2Name == name }.count
    }

    static func wins(name: String, in results: [GameResult]) -> Int {
        results.filter { $0.winnerName == name }.count
    }

    /// Longest run of consecutive wins for `name`, in the order results are given.
    static func longestStreak(name: String, in results: [GameResult]) -> Int {
        var best = 0, run = 0
        for r in results where r.player1Name == name || r.player2Name == name {
            if r.winnerName == name { run += 1; best = max(best, run) } else { run = 0 }
        }
        return best
    }

    /// Head-to-head record between two specific players across the given results,
    /// counting only games where both names appear (the matchup).
    static func headToHead(player1: String, player2: String, in results: [GameResult])
        -> (p1Wins: Int, p2Wins: Int, games: Int) {
        let matchup = results.filter {
            ($0.player1Name == player1 || $0.player2Name == player1) &&
            ($0.player1Name == player2 || $0.player2Name == player2)
        }
        let p1 = matchup.filter { $0.winnerName == player1 }.count
        let p2 = matchup.filter { $0.winnerName == player2 }.count
        return (p1, p2, matchup.count)
    }

    /// Average absolute final-score margin across all results, rounded. 0 when empty.
    static func averageWinningMargin(in results: [GameResult]) -> Int {
        guard !results.isEmpty else { return 0 }
        let total = results.reduce(0) { $0 + abs($1.player1Total - $1.player2Total) }
        return Int((Double(total) / Double(results.count)).rounded())
    }

    /// Highest finishing score reached by either player across all results. 0 when empty.
    static func bestScore(in results: [GameResult]) -> Int {
        results.flatMap { [$0.player1Total, $0.player2Total] }.max() ?? 0
    }
}
