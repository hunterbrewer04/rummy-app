import SwiftUI
import SwiftData

/// Home dashboard: head-to-head series hero, in-progress game, recent games.
struct GamesListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Game.createdAt, order: .reverse) private var games: [Game]
    @State private var showingNewGame = false
    @State private var pendingDelete: Game?

    /// Finished games as plain results, oldest → newest (for streak/series math).
    private var results: [GameResult] {
        games.reversed().compactMap { g in
            guard let w = g.winnerName else { return nil }
            return GameResult(player1Name: g.player1Name, player2Name: g.player2Name,
                              player1Total: g.player1Total, player2Total: g.player2Total, winnerName: w)
        }
    }

    private var activeGame: Game? { games.first { !$0.isFinished } }
    private var finishedGames: [Game] { games.filter { $0.isFinished } }

    var body: some View {
        NavigationStack {
            Group {
                if games.isEmpty {
                    ContentUnavailableView(
                        "No games yet",
                        systemImage: "suit.club.fill",
                        description: Text("Tap New Game to start your first game.")
                    )
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 14) {
                            hero
                            if let active = activeGame {
                                Text("In progress").sectionLabelStyle()
                                NavigationLink { GameDetailView(game: active) } label: {
                                    ResumeCard(game: active)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button("Delete", systemImage: "trash", role: .destructive) {
                                        pendingDelete = active
                                    }
                                }
                            }
                            if !finishedGames.isEmpty {
                                Text("Recent").sectionLabelStyle().padding(.top, 4)
                                ForEach(finishedGames) { game in
                                    NavigationLink { GameDetailView(game: game) } label: {
                                        GameCard(game: game)
                                    }
                                    .buttonStyle(.plain)
                                    .contextMenu {
                                        Button("Delete", systemImage: "trash", role: .destructive) {
                                            pendingDelete = game
                                        }
                                    }
                                }
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Rummy").font(.system(size: 20, weight: .heavy)).foregroundStyle(Theme.textPrimary)
                }
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink { StatsView() } label: { Image(systemName: "chart.bar.fill") }
                }
            }
            .safeAreaInset(edge: .bottom) {
                PrimaryButton(title: "New Game", systemImage: "plus") { showingNewGame = true }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
            }
            .sheet(isPresented: $showingNewGame) { NewGameView() }
            .confirmationDialog("Delete this game?",
                                isPresented: Binding(get: { pendingDelete != nil },
                                                     set: { if !$0 { pendingDelete = nil } }),
                                titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    if let g = pendingDelete { context.delete(g) }
                    pendingDelete = nil
                }
                Button("Cancel", role: .cancel) { pendingDelete = nil }
            }
        }
    }

    /// Head-to-head hero card for the (fixed) matchup, derived from the most recent game.
    @ViewBuilder
    private var hero: some View {
        // Anchor the matchup on the most recent FINISHED game so the hero's
        // player→color assignment matches StatsView; fall back to the newest
        // game (e.g. when only an in-progress game exists) for a 0–0 cold start.
        if let recent = finishedGames.first ?? games.first {
            let h = StatsEngine.headToHead(player1: recent.player1Name,
                                           player2: recent.player2Name, in: results)
            SlateFaceoffCard(name1: recent.player1Name, wins1: h.p1Wins,
                             name2: recent.player2Name, wins2: h.p2Wins,
                             centerLabel: "SERIES",
                             subtitle: "\(h.games) games played")
        }
    }
}
