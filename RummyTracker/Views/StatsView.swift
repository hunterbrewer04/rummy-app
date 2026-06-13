import SwiftUI
import SwiftData

struct StatsView: View {
    @Query(sort: \Game.finishedAt, order: .forward) private var games: [Game]

    private var results: [GameResult] {
        games.compactMap { g in
            guard let w = g.winnerName else { return nil }  // finished games only
            return GameResult(player1Name: g.player1Name, player2Name: g.player2Name,
                              player1Total: g.player1Total, player2Total: g.player2Total, winnerName: w)
        }
    }

    var body: some View {
        List {
            if results.isEmpty {
                ContentUnavailableView("No finished games yet", systemImage: "chart.bar")
            } else {
                ForEach(StatsEngine.standings(from: results), id: \.name) { s in
                    Section(s.name) {
                        LabeledContent("Record", value: "\(s.wins)–\(s.losses)")
                        LabeledContent("Win rate", value: "\(s.winPercent)%")
                        LabeledContent("Longest streak", value: "\(s.longestStreak)")
                        LabeledContent("Games played", value: "\(s.gamesPlayed)")
                    }
                }
            }
        }
        .navigationTitle("Stats")
    }
}
