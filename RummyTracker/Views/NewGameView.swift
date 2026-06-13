import SwiftUI
import SwiftData

/// Sheet for starting a new game: two player names and a target score.
struct NewGameView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var player1 = ""
    @State private var player2 = ""
    @State private var target = 500

    var body: some View {
        NavigationStack {
            Form {
                Section("Players") {
                    TextField("Player 1 name", text: $player1)
                    TextField("Player 2 name", text: $player2)
                }
                Section("Target Score") {
                    Stepper("First to \(target)", value: $target, in: 50...2000, step: 50)
                }
            }
            .navigationTitle("New Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start") { start() }
                        .disabled(!isValid)
                }
            }
        }
    }

    private var trimmedPlayer1: String { player1.trimmingCharacters(in: .whitespaces) }
    private var trimmedPlayer2: String { player2.trimmingCharacters(in: .whitespaces) }

    private var isValid: Bool {
        !trimmedPlayer1.isEmpty && !trimmedPlayer2.isEmpty
    }

    private func start() {
        let game = Game(
            player1Name: trimmedPlayer1,
            player2Name: trimmedPlayer2,
            targetScore: target
        )
        context.insert(game)
        dismiss()
    }
}
