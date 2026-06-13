import SwiftUI

/// Lightweight emoji confetti. Drop over content with `.overlay`.
struct ConfettiView: View {
    /// One confetti piece's fixed properties, rolled once so parent
    /// re-renders don't make pieces jump mid-fall.
    private struct Piece: Identifiable {
        let id: Int
        let emoji: String
        let xFraction: CGFloat
        let duration: Double
        let delay: Double
    }

    @State private var animate = false
    @State private var pieces: [Piece] = {
        let emojis = ["🎉", "🃏", "♣️", "♦️", "♥️", "♠️", "⭐️"]
        return (0..<40).map { i in
            Piece(
                id: i,
                emoji: emojis[i % emojis.count],
                xFraction: CGFloat.random(in: 0...1),
                duration: Double.random(in: 1.5...2.8),
                delay: Double(i) * 0.02
            )
        }
    }()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(pieces) { piece in
                    Text(piece.emoji)
                        .font(.system(size: 26))
                        .position(
                            x: piece.xFraction * geo.size.width,
                            y: animate ? geo.size.height + 40 : -40
                        )
                        .opacity(animate ? 0 : 1)
                        .animation(.easeIn(duration: piece.duration)
                            .delay(piece.delay), value: animate)
                }
            }
            // Kick off after a tick so the first layout pass renders the
            // start state — otherwise pieces can snap straight to the end.
            .task {
                try? await Task.sleep(for: .milliseconds(50))
                animate = true
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true) // purely decorative
        }
        .ignoresSafeArea()
    }
}
