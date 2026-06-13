import SwiftUI
import SwiftData

/// Sheet for entering (or editing) one hand's scores for both players.
struct AddHandView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let game: Game
    /// When set, we edit this hand instead of creating a new one.
    var editingHand: Hand? = nil

    @State private var player1Text = ""
    @State private var player2Text = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                playerBlock(name: game.player1Name, player: 1, text: $player1Text)
                Divider().overlay(Theme.divider).padding(.horizontal, 18)
                playerBlock(name: game.player2Name, player: 2, text: $player2Text)
                Spacer(minLength: 0)
                PrimaryButton(title: "Save Hand") { save() }
                    .padding(.horizontal, 15)
                    .padding(.bottom, 15)
                    .opacity(isValid ? 1 : 0.5)
                    .disabled(!isValid)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle(editingHand == nil ? "Add Hand" : "Edit Hand")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(!isValid).fontWeight(.heavy)
                }
            }
            .onAppear(perform: populateForEdit)
        }
    }

    private func playerBlock(name: String, player: Int, text: Binding<String>) -> some View {
        let accent = Theme.playerColor(player)
        return VStack(spacing: 12) {
            HStack(spacing: 7) {
                Circle().fill(accent).frame(width: 9, height: 9)
                Text(name).font(.system(size: 14, weight: .heavy)).foregroundStyle(accent)
            }
            TextField("0", text: text)
                .keyboardType(.numbersAndPunctuation)
                .multilineTextAlignment(.center)
                .font(Theme.number(40))
                .foregroundStyle(accent)
                .frame(maxWidth: 150)
                .padding(.bottom, 4)
                .overlay(alignment: .bottom) { Rectangle().fill(accent).frame(height: 2.5) }
            HStack(spacing: 8) {
                ForEach([5, 10, 25, 50], id: \.self) { amount in
                    ScoreChip(amount: amount, player: player) { adjust(text, by: amount) }
                }
            }
            .padding(.horizontal, 18)
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
    }

    /// Adds `delta` to the current parsed value (treating blank/invalid as 0).
    private func adjust(_ text: Binding<String>, by delta: Int) {
        let current = parsedScore(text.wrappedValue) ?? 0
        text.wrappedValue = String(current + delta)
    }

    private func populateForEdit() {
        guard let hand = editingHand else { return }
        player1Text = String(hand.player1Score)
        player2Text = String(hand.player2Score)
    }

    /// A blank field means 0; otherwise it must be a whole number. Normalizes
    /// the unicode dashes the keyboard can produce so "−5" / "–5" parse like "-5".
    private func parsedScore(_ text: String) -> Int? {
        let cleaned = text
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "\u{2212}", with: "-")  // minus sign
            .replacingOccurrences(of: "\u{2013}", with: "-")  // en dash
            .replacingOccurrences(of: "\u{2014}", with: "-")  // em dash
        if cleaned.isEmpty { return 0 }
        return Int(cleaned)
    }

    /// Both fields must be blank or a valid whole number before saving, so a
    /// typo like "5-3" can't be silently stored as 0.
    private var isValid: Bool {
        parsedScore(player1Text) != nil && parsedScore(player2Text) != nil
    }

    private func save() {
        let p1 = parsedScore(player1Text) ?? 0
        let p2 = parsedScore(player2Text) ?? 0

        if let hand = editingHand {
            hand.player1Score = p1
            hand.player2Score = p2
        } else {
            let hand = Hand(index: game.nextHandIndex, player1Score: p1, player2Score: p2)
            hand.game = game
            context.insert(hand)
        }
        game.finalizeIfNeeded()
        dismiss()
    }
}
