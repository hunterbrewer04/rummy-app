import SwiftUI

/// Central design tokens for the Cobalt & Coral redesign. Adaptive colors
/// resolve from the asset catalog (light/dark). The slate panel and its bright
/// accents are constant because the slate card is always dark in both modes.
enum Theme {
    static let background = Color("AppBackground")
    static let card = Color("CardSurface")
    static let textPrimary = Color("TextPrimary")
    static let player1 = Color("Player1")
    static let player2 = Color("Player2")
    static let progressTrack = Color("ProgressTrack")
    static let divider = Color("Divider")

    static var textSecondary: Color { textPrimary.opacity(0.55) }

    /// Dark gradient used by the faceoff / score panels.
    static let slate = LinearGradient(
        colors: [Color(red: 0x22 / 255, green: 0x2B / 255, blue: 0x40 / 255),
                 Color(red: 0x15 / 255, green: 0x1A / 255, blue: 0x28 / 255)],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    /// Brighter accents that read on the dark slate.
    static let player1OnSlate = Color(red: 0x5B / 255, green: 0x8C / 255, blue: 0xFF / 255)
    static let player2OnSlate = Color(red: 0xFF / 255, green: 0x84 / 255, blue: 0x97 / 255)

    static func playerColor(_ player: Int) -> Color { player == 1 ? player1 : player2 }
    static func playerColorOnSlate(_ player: Int) -> Color { player == 1 ? player1OnSlate : player2OnSlate }

    /// SF Rounded, heavy — the signature numeral style.
    static func number(_ size: CGFloat) -> Font { .system(size: size, weight: .heavy, design: .rounded) }

    static let cardRadius: CGFloat = 18
}

extension View {
    /// Standard card chrome: surface fill, rounded corners, soft shadow.
    func cardSurface(padding: CGFloat = 14, radius: CGFloat = Theme.cardRadius) -> some View {
        self
            .padding(padding)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    /// Small uppercase tracked section label.
    func sectionLabelStyle() -> some View {
        self.font(.system(size: 11, weight: .bold))
            .tracking(1)
            .foregroundStyle(Theme.textSecondary)
            .textCase(.uppercase)
    }
}
