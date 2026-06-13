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
            Form {
                Section {
                    scoreRow(label: game.player1Name, text: $player1Text)
                    scoreRow(label: game.player2Name, text: $player2Text)
                } footer: {
                    Text("Enter this hand's points for each player. Use the buttons for quick entry; negative numbers are allowed.")
                }
            }
            .navigationTitle(editingHand == nil ? "Add Hand" : "Edit Hand")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!isValid)
                }
            }
            .onAppear(perform: populateForEdit)
        }
    }

    private func scoreRow(label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label).font(.headline)
                Spacer()
                TextField("0", text: text)
                    .keyboardType(.numbersAndPunctuation)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 90)
                    .textFieldStyle(.roundedBorder)
            }
            HStack(spacing: 8) {
                Button { adjust(text, by: -5) } label: {
                    Image(systemName: "minus.circle.fill")
                }
                .accessibilityLabel("Minus 5")
                ForEach([5, 10, 25, 50], id: \.self) { amount in
                    Button("+\(amount)") { adjust(text, by: amount) }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.accentColor.opacity(0.15), in: Capsule())
                }
                Spacer()
            }
            .font(.title3)
            .buttonStyle(.borderless)   // every button opts out of the Form row tap
        }
        .padding(.vertical, 4)
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
        // isValid gates the Save button, so these are guaranteed non-nil here.
        let p1 = parsedScore(player1Text) ?? 0
        let p2 = parsedScore(player2Text) ?? 0

        if let hand = editingHand {
            hand.player1Score = p1
            hand.player2Score = p2
        } else {
            let hand = Hand(index: game.nextHandIndex, player1Score: p1, player2Score: p2)
            hand.game = game            // wires up the inverse relationship
            context.insert(hand)
        }
        dismiss()
    }
}
