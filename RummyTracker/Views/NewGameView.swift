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
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Players").sectionLabelStyle()
                    nameField(player: 1, placeholder: "Player 1 name", text: $player1)
                    nameField(player: 2, placeholder: "Player 2 name", text: $player2)

                    Text("Target Score").sectionLabelStyle().padding(.top, 6)
                    TargetSegmented(target: $target, presets: [250, 500, 1000])
                    Stepper("First to \(target)", value: $target, in: 50...2000, step: 50)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)

                    PrimaryButton(title: "Start Game") { start() }
                        .opacity(isValid ? 1 : 0.5)
                        .disabled(!isValid)
                        .padding(.top, 10)
                }
                .padding(16)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("New Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start") { start() }.disabled(!isValid).fontWeight(.heavy)
                }
            }
        }
    }

    private func nameField(player: Int, placeholder: String, text: Binding<String>) -> some View {
        let accent = Theme.playerColor(player)
        return VStack(alignment: .leading, spacing: 4) {
            Text("Player \(player)")
                .font(.system(size: 9, weight: .bold)).tracking(0.8)
                .foregroundStyle(accent).textCase(.uppercase)
            TextField(placeholder, text: text)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
        }
        .cardSurface(padding: 12)
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2).fill(accent).frame(width: 4).padding(.vertical, 10)
        }
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
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
