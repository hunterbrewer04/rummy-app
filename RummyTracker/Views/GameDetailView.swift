import SwiftUI
import SwiftData

/// The scoreboard for one game: running totals, a winner banner once decided,
/// and the list of hands played.
struct GameDetailView: View {
    let game: Game
    @Environment(\.modelContext) private var context
    @State private var showingAddHand = false

    var body: some View {
        List {
            Section {
                ScoreHeaderView(game: game)
            }

            if let winner = game.winnerName {
                Section {
                    VStack(spacing: 4) {
                        Text("🏆").font(.largeTitle)
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
                    .onDelete(perform: deleteHands)
                }
            }
        }
        .navigationTitle("\(game.player1Name) vs \(game.player2Name)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddHand = true
                } label: {
                    Label("Add Hand", systemImage: "plus")
                }
                .disabled(game.isFinished)
            }
        }
        .sheet(isPresented: $showingAddHand) {
            AddHandView(game: game)
        }
    }

    private func deleteHands(at offsets: IndexSet) {
        let ordered = game.orderedHands
        for index in offsets {
            context.delete(ordered[index])
        }
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
                    isWinner: game.winningPlayer == 1
                )
                Divider()
                PlayerScoreColumn(
                    name: game.player2Name,
                    score: game.player2Total,
                    target: game.targetScore,
                    isWinner: game.winningPlayer == 2
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
            editing = true
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
