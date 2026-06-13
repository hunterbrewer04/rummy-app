import Testing
@testable import RummyTracker

private let sampleResults: [GameResult] = [
    GameResult(player1Name: "A", player2Name: "B", player1Total: 500, player2Total: 320, winnerName: "A"),
    GameResult(player1Name: "A", player2Name: "B", player1Total: 510, player2Total: 410, winnerName: "A"),
    GameResult(player1Name: "A", player2Name: "B", player1Total: 300, player2Total: 500, winnerName: "B"),
]

@Suite("StatsEngine")
struct StatsEngineTests {

    @Test func aHasTwoWins() {
        #expect(StatsEngine.wins(name: "A", in: sampleResults) == 2)
    }

    @Test func aPlayedThreeGames() {
        #expect(StatsEngine.gamesPlayed(name: "A", in: sampleResults) == 3)
    }

    @Test func aLongestStreakIsTwo() {
        #expect(StatsEngine.longestStreak(name: "A", in: sampleResults) == 2)
    }

    @Test func aLeadsStandings() {
        #expect(StatsEngine.standings(from: sampleResults).first?.name == "A")
    }

    @Test func longestStreakIsOrderSensitive() {
        let interleaved = [
            GameResult(player1Name: "A", player2Name: "B", player1Total: 500, player2Total: 100, winnerName: "A"),
            GameResult(player1Name: "A", player2Name: "B", player1Total: 100, player2Total: 500, winnerName: "B"),
            GameResult(player1Name: "A", player2Name: "B", player1Total: 500, player2Total: 100, winnerName: "A"),
        ]
        #expect(StatsEngine.longestStreak(name: "A", in: interleaved) == 1)
    }
}
