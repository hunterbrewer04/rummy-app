import SwiftUI
import SwiftData

struct StatsView: View {
    @Query(sort: \Game.finishedAt, order: .forward) private var games: [Game]

    /// Finished games as plain results, oldest → newest (for streak ordering).
    private var results: [GameResult] {
        games.compactMap { g in
            guard let w = g.winnerName else { return nil }  // finished games only
            return GameResult(player1Name: g.player1Name, player2Name: g.player2Name,
                              player1Total: g.player1Total, player2Total: g.player2Total, winnerName: w)
        }
    }

    var body: some View {
        ScrollView {
            if results.isEmpty {
                ContentUnavailableView("No finished games yet", systemImage: "chart.bar")
                    .padding(.top, 80)
            } else {
                content
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Stats")
    }

    @ViewBuilder
    private var content: some View {
        let r = results
        // The most recent finished game defines the matchup names.
        let p1 = r.last!.player1Name
        let p2 = r.last!.player2Name
        let h = StatsEngine.headToHead(player1: p1, player2: p2, in: r)
        let p1Rate = h.games == 0 ? 0 : Int((Double(h.p1Wins) / Double(h.games) * 100).rounded())
        let p2Rate = h.games == 0 ? 0 : Int((Double(h.p2Wins) / Double(h.games) * 100).rounded())

        VStack(alignment: .leading, spacing: 16) {
            SlateFaceoffCard(name1: p1, wins1: h.p1Wins, name2: p2, wins2: h.p2Wins,
                             centerLabel: "SERIES", subtitle: "\(h.games) games played")

            let columns = [GridItem(.flexible(), spacing: 9), GridItem(.flexible(), spacing: 9)]
            LazyVGrid(columns: columns, spacing: 9) {
                StatTile(value: "\(p1Rate)%", caption: "\(p1) win rate", valueColor: Theme.player1)
                StatTile(value: "\(p2Rate)%", caption: "\(p2) win rate", valueColor: Theme.player2)
                StatTile(value: "\(StatsEngine.averageWinningMargin(in: r))", caption: "Avg margin")
                StatTile(value: "\(StatsEngine.bestScore(in: r))", caption: "Best score")
            }

            Text("Last 6").sectionLabelStyle()
            StreakStrip(entries: recentEntries(p1: p1, in: r))
        }
        .padding(16)
    }

    /// The last six results as colored streak entries (winner's initial + color).
    private func recentEntries(p1: String, in results: [GameResult]) -> [StreakEntry] {
        results.suffix(6).map { r in
            let player = (r.winnerName == p1) ? 1 : 2
            let initial = String(r.winnerName.prefix(1)).uppercased()
            return StreakEntry(initial: initial, player: player)
        }
    }
}
