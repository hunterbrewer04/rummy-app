import SwiftUI
import SwiftData

/// Home screen: a win tally across all finished games plus the list of games,
/// newest first.
struct GamesListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Game.createdAt, order: .reverse) private var games: [Game]
    @State private var showingNewGame = false
    @State private var pendingDelete: IndexSet?

    var body: some View {
        NavigationStack {
            Group {
                if games.isEmpty {
                    ContentUnavailableView(
                        "No games yet",
                        systemImage: "suit.club.fill",
                        description: Text("Tap + to start your first game.")
                    )
                } else {
                    List {
                        WinTallyView(games: games)

                        Section("Games") {
                            ForEach(games) { game in
                                NavigationLink {
                                    GameDetailView(game: game)
                                } label: {
                                    GameRow(game: game)
                                }
                            }
                            .onDelete { pendingDelete = $0 }
                        }
                    }
                    .confirmationDialog("Delete this game?",
                                        isPresented: .constant(pendingDelete != nil),
                                        titleVisibility: .visible) {
                        Button("Delete", role: .destructive) {
                            if let offsets = pendingDelete { deleteGames(at: offsets) }
                            pendingDelete = nil
                        }
                        Button("Cancel", role: .cancel) { pendingDelete = nil }
                    }
                }
            }
            .navigationTitle("Rummy")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink { StatsView() } label: { Label("Stats", systemImage: "chart.bar.fill") }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingNewGame = true
                    } label: {
                        Label("New Game", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewGame) {
                NewGameView()
            }
        }
    }

    private func deleteGames(at offsets: IndexSet) {
        for index in offsets {
            context.delete(games[index])
        }
    }
}

/// Counts wins per player name across all finished games.
private struct WinTallyView: View {
    let games: [Game]

    private var standings: [(name: String, wins: Int)] {
        var counts: [String: Int] = [:]
        for game in games where game.isFinished {
            if let winner = game.winnerName {
                counts[winner, default: 0] += 1
            }
        }
        return counts
            .sorted { $0.value > $1.value }
            .map { (name: $0.key, wins: $0.value) }
    }

    var body: some View {
        if !standings.isEmpty {
            Section("Win Record") {
                ForEach(standings, id: \.name) { standing in
                    HStack {
                        Text(standing.name)
                        Spacer()
                        Text("\(standing.wins) win\(standing.wins == 1 ? "" : "s")")
                            .fontWeight(.semibold)
                    }
                }
            }
        }
    }
}

/// One row in the games list.
private struct GameRow: View {
    let game: Game

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("\(game.player1Name) vs \(game.player2Name)")
                    .font(.headline)
                Spacer()
                if game.isFinished {
                    Image(systemName: "trophy.fill")
                        .foregroundStyle(.yellow)
                }
            }
            HStack {
                Text("\(game.player1Total) – \(game.player2Total)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                if let winner = game.winnerName {
                    Text("🏆 \(winner)")
                        .font(.caption)
                } else {
                    Text(game.createdAt, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}
