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
                ScorePanel(game: game)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 4, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }

            if let winner = game.winnerName {
                Section {
                    let player = (winner == game.player2Name) ? 2 : 1
                    VStack(spacing: 8) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(Theme.playerColor(player))
                            .symbolEffect(.bounce, value: celebrate)
                            .accessibilityHidden(true) // decorative; "X wins!" conveys the result
                        Text("\(winner) wins!")
                            .font(.system(size: 18, weight: .heavy))
                            .foregroundStyle(Theme.textPrimary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
            }

            Section {
                if game.hands.isEmpty {
                    Text("No hands yet. Tap \u{201C}Add Hand\u{201D}.")
                        .foregroundStyle(Theme.textSecondary)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                } else {
                    ForEach(Array(game.orderedHands.enumerated()), id: \.element.id) { offset, hand in
                        HandRow(number: offset + 1, game: game, hand: hand)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                    .onDelete(perform: game.isFinished ? nil : deleteHands)
                }
            } header: {
                Text("Hands").sectionLabelStyle()
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Theme.background.ignoresSafeArea())
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
        .safeAreaInset(edge: .bottom) {
            if !game.isFinished {
                PrimaryButton(title: "Add Hand", systemImage: "plus") { showingAddHand = true }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
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
                    Menu {
                        Button("Rematch", systemImage: "arrow.clockwise") { startRematch() }
                        Button("Reopen Game", systemImage: "lock.open", role: .destructive) {
                            showingReopenConfirm = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
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

    private func startRematch() {
        let new = Game(player1Name: game.player1Name,
                       player2Name: game.player2Name,
                       targetScore: game.targetScore)
        context.insert(new)
        rematch = new
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

/// One hand row as a card. Tapping opens the editor (disabled when finished);
/// swipe to delete is handled by the parent List.
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
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                Text("\(hand.player1Score)")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.player1)
                    .frame(minWidth: 44, alignment: .trailing)
                Text("\(hand.player2Score)")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.player2)
                    .frame(minWidth: 44, alignment: .trailing)
            }
            .cardSurface(padding: 12)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $editing) {
            AddHandView(game: game, editingHand: hand)
        }
    }
}
