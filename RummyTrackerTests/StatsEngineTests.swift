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

    @Test func headToHeadCountsMatchupWins() {
        let h = StatsEngine.headToHead(player1: "A", player2: "B", in: sampleResults)
        #expect(h.p1Wins == 2)
        #expect(h.p2Wins == 1)
        #expect(h.games == 3)
    }

    @Test func headToHeadExcludesOtherMatchups() {
        let mixed: [GameResult] = [
            GameResult(player1Name: "A", player2Name: "B", player1Total: 500, player2Total: 300, winnerName: "A"),
            GameResult(player1Name: "A", player2Name: "C", player1Total: 500, player2Total: 480, winnerName: "A"),
            GameResult(player1Name: "B", player2Name: "C", player1Total: 510, player2Total: 200, winnerName: "B"),
        ]
        let h = StatsEngine.headToHead(player1: "A", player2: "B", in: mixed)
        #expect(h.games == 1)   // only the A-vs-B game counts
        #expect(h.p1Wins == 1)
        #expect(h.p2Wins == 0)
    }

    @Test func averageMarginRounds() {
        // |500-320|=180, |510-410|=100, |300-500|=200 -> avg 160
        #expect(StatsEngine.averageWinningMargin(in: sampleResults) == 160)
    }

    @Test func bestScoreIsMaxTotal() {
        #expect(StatsEngine.bestScore(in: sampleResults) == 510)
    }

    @Test func emptyResultsAreSafe() {
        #expect(StatsEngine.averageWinningMargin(in: []) == 0)
        #expect(StatsEngine.bestScore(in: []) == 0)
    }
}
