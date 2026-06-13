import SwiftUI
import SwiftData

/// The scoreboard for one game: running totals, a winner banner once decided,
/// and the list of hands played.
struct GameDetailView: View {
    let game: Game
    @Environment(\.modelContext) private var context
    @State private var showingAddHand = false
    /// Drives the trophy bounce; toggled on appear (already-finished games) and on live finish.
    @State private var celebrate = false
    @State private var lastDeleted: [(p1: Int, p2: Int, index: Int)] = []
    @State private var showUndo = false
    @State private var undoToken = 0
    @State private var showingReopenConfirm = false
    @State private var rematch: Game?

    var body: some View {
        List {
            Section {
                ScoreHeaderView(game: game)
            }

            if let winner = game.winnerName {
                Section {
                    VStack(spacing: 8) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.yellow)
                            .symbolEffect(.bounce, value: celebrate)
                            .accessibilityHidden(true) // decorative; "X wins!" conveys the result
                        Text("\(winner) wins!").font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }

            Section("Hands") {
                if game.hands.isEmpty {
                    Text("No hands yet. Tap “Add Hand”.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(game.orderedHands.enumerated()), id: \.element.id) { offset, hand in
                        HandRow(number: offset + 1, game: game, hand: hand)
                    }
                    .onDelete(perform: game.isFinished ? nil : deleteHands)
                }
            }
        }
        .navigationTitle("\(game.player1Name) vs \(game.player2Name)")
        .navigationBarTitleDisplayMode(.inline)
        // Closure form intentionally suppresses the haptic on the un-finish transition.
        .sensoryFeedback(trigger: game.isFinished) { _, isFinished in
            isFinished ? .success : nil
        }
        // `.id` forces a fresh confetti run if the winner changes.
        .overlay { if game.isFinished { ConfettiView().id(game.winnerName) } }
        .overlay(alignment: .bottom) {
            if showUndo {
                HStack {
                    Text("Hand deleted")
                    Spacer()
                    Button("Undo") { undoDelete() }.bold()
                }
                .padding().background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .padding()
                .id(undoToken)
                .task {
                    try? await Task.sleep(for: .seconds(4))
                    showUndo = false
                }
            }
        }
        .onAppear {
            if game.isFinished { celebrate.toggle() }
        }
        .onChange(of: game.isFinished) { _, isFinished in
            if isFinished { celebrate.toggle() }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if game.isFinished {
                    Button("Rematch", systemImage: "arrow.clockwise") {
                        let new = Game(player1Name: game.player1Name,
                                       player2Name: game.player2Name,
                                       targetScore: game.targetScore)
                        context.insert(new)
                        rematch = new
                    }
                } else {
                    Button {
                        showingAddHand = true
                    } label: {
                        Label("Add Hand", systemImage: "plus")
                    }
                }
            }
            ToolbarItem(placement: .secondaryAction) {
                if game.isFinished {
                    Button("Reopen Game", systemImage: "lock.open") { showingReopenConfirm = true }
                }
            }
        }
        .navigationDestination(item: $rematch) { GameDetailView(game: $0) }
        .sheet(isPresented: $showingAddHand) {
            AddHandView(game: game)
        }
        .confirmationDialog(
            "Reopen this game? The recorded result will be cleared.",
            isPresented: $showingReopenConfirm,
            titleVisibility: .visible
        ) {
            Button("Reopen", role: .destructive) { game.reopen() }
            Button("Cancel", role: .cancel) { }
        }
    }

    private func deleteHands(at offsets: IndexSet) {
        let ordered = game.orderedHands
        lastDeleted = offsets.map {
            let h = ordered[$0]
            return (h.player1Score, h.player2Score, h.index)
        }
        for index in offsets { context.delete(ordered[index]) }
        undoToken += 1
        showUndo = true
    }

    private func undoDelete() {
        guard !lastDeleted.isEmpty else { return }
        for d in lastDeleted {
            let hand = Hand(index: d.index, player1Score: d.p1, player2Score: d.p2)
            hand.game = game
            context.insert(hand)
        }
        game.finalizeIfNeeded()
        lastDeleted = []
        showUndo = false
    }
}

/// Big side-by-side totals with progress toward the target.
private struct ScoreHeaderView: View {
    let game: Game

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top) {
                PlayerScoreColumn(
                    name: game.player1Name,
                    score: game.player1Total,
                    target: game.targetScore,
                    isWinner: game.winningPlayerLive == 1
                )
                Divider()
                PlayerScoreColumn(
                    name: game.player2Name,
                    score: game.player2Total,
                    target: game.targetScore,
                    isWinner: game.winningPlayerLive == 2
                )
            }
            Text("First to \(game.targetScore)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
    }
}

private struct PlayerScoreColumn: View {
    let name: String
    let score: Int
    let target: Int
    let isWinner: Bool

    var body: some View {
        VStack(spacing: 6) {
            Text(name)
                .font(.headline)
                .lineLimit(1)
            Text("\(score)")
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundStyle(isWinner ? .green : .primary)
                .contentTransition(.numericText())
            // Clamp progress to 0...target so negative scores don't break the bar.
            ProgressView(
                value: Double(max(0, min(score, target))),
                total: Double(target)
            )
            .tint(isWinner ? .green : .blue)
        }
        .frame(maxWidth: .infinity)
    }
}

/// One hand row. Tapping opens the editor; swipe to delete (handled by parent).
private struct HandRow: View {
    let number: Int
    let game: Game
    let hand: Hand
    @State private var editing = false

    var body: some View {
        Button {
            if !game.isFinished { editing = true }
        } label: {
            HStack {
                Text("Hand \(number)")
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(hand.player1Score)")
                    .frame(minWidth: 48, alignment: .trailing)
                Text("\(hand.player2Score)")
                    .frame(minWidth: 48, alignment: .trailing)
                    .fontWeight(.medium)
            }
        }
        .foregroundStyle(.primary)
        .sheet(isPresented: $editing) {
            AddHandView(game: game, editingHand: hand)
        }
    }
}
