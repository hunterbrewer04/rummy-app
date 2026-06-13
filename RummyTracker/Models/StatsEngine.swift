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
}
