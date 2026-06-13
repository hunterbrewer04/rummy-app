import Testing
@testable import RummyTracker

/// Tests for the pure scoring rules. No UI or database needed.
struct ScoringEngineTests {

    @Test func totalSumsScores() {
        #expect(ScoringEngine.total(of: [10, 20, 30]) == 60)
    }

    @Test func totalHandlesNegatives() {
        #expect(ScoringEngine.total(of: [50, -20, 10]) == 40)
    }

    @Test func emptyTotalIsZero() {
        #expect(ScoringEngine.total(of: []) == 0)
    }

    @Test func noWinnerBelowTarget() {
        #expect(ScoringEngine.winner(player1Total: 480, player2Total: 300, target: 500) == nil)
    }

    @Test func winnerAtExactlyTarget() {
        #expect(ScoringEngine.winner(player1Total: 500, player2Total: 300, target: 500) == 1)
    }

    @Test func winnerAboveTarget() {
        #expect(ScoringEngine.winner(player1Total: 200, player2Total: 530, target: 500) == 2)
    }

    @Test func bothOverTargetHigherWins() {
        #expect(ScoringEngine.winner(player1Total: 510, player2Total: 540, target: 500) == 2)
    }

    @Test func exactTieAtTargetIsUndecided() {
        #expect(ScoringEngine.winner(player1Total: 500, player2Total: 500, target: 500) == nil)
    }

    @Test func decidedWinnerNameReturnsLeader() {
        #expect(ScoringEngine.decidedWinnerName(player1Name: "A", player2Name: "B",
            player1Total: 510, player2Total: 300, target: 500) == "A")
    }

    @Test func decidedWinnerNameNilWhenUndecided() {
        #expect(ScoringEngine.decidedWinnerName(player1Name: "A", player2Name: "B",
            player1Total: 200, player2Total: 200, target: 500) == nil)
    }
}
