import SwiftUI

/// Filled cobalt call-to-action button.
struct PrimaryButton: View {
    let title: String
    var systemImage: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage { Image(systemName: systemImage) }
                Text(title).fontWeight(.heavy)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .foregroundStyle(.white)
            .background(Theme.player1, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
            .shadow(color: Theme.player1.opacity(0.35), radius: 12, x: 0, y: 8)
        }
        .buttonStyle(.plain)
    }
}

/// "+N" quick-add chip in a player's color (Add Hand).
struct ScoreChip: View {
    let amount: Int
    let player: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("+\(amount)")
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .foregroundStyle(Theme.playerColor(player))
                .background(Theme.playerColor(player).opacity(0.14), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

/// Segmented preset picker for the target score (New Game).
struct TargetSegmented: View {
    @Binding var target: Int
    let presets: [Int]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(presets, id: \.self) { value in
                let on = value == target
                Button { target = value } label: {
                    Text("\(value)")
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .foregroundStyle(on ? .white : Theme.textPrimary)
                        .background(on ? Theme.player1 : Theme.card,
                                    in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// One finished/in-progress game row on the Home screen.
struct GameCard: View {
    let game: Game

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("\(game.player1Name) vs \(game.player2Name)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text("\(game.player1Total) – \(game.player2Total)")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            if let winner = game.winnerName {
                let player = (winner == game.player2Name) ? 2 : 1
                HStack(spacing: 4) {
                    Image(systemName: "trophy.fill")
                    Text(winner).font(.system(size: 12, weight: .bold)).lineLimit(1)
                }
                .foregroundStyle(Theme.playerColor(player))
            } else {
                Text(game.createdAt, style: .date)
                    .font(.caption).foregroundStyle(Theme.textSecondary)
            }
        }
        .cardSurface()
    }
}

/// Bordered "resume the in-progress game" card.
struct ResumeCard: View {
    let game: Game

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("\(game.player1Name) vs \(game.player2Name)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text("\(game.player1Total) – \(game.player2Total)")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.player1)
            }
            Spacer()
            Text("RESUME")
                .font(.system(size: 10, weight: .heavy)).tracking(0.5)
                .foregroundStyle(.white)
                .padding(.horizontal, 13).padding(.vertical, 6)
                .background(Theme.player1, in: Capsule())
        }
        .padding(14)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
            .strokeBorder(Theme.player1, lineWidth: 1.5))
    }
}

/// A single stat tile: big rounded number + uppercase caption.
struct StatTile: View {
    let value: String
    let caption: String
    var valueColor: Color = Theme.textPrimary

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(Theme.number(22)).foregroundStyle(valueColor)
            Text(caption)
                .font(.system(size: 9, weight: .semibold)).tracking(0.5)
                .foregroundStyle(Theme.textSecondary).textCase(.uppercase)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(padding: 12)
    }
}

/// One entry in the recent-results streak strip.
struct StreakEntry {
    let initial: String
    let player: Int
}

/// Row of small colored squares, one per recent game, in the winner's color.
struct StreakStrip: View {
    let entries: [StreakEntry]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Array(entries.enumerated()), id: \.offset) { _, e in
                Text(e.initial)
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .frame(width: 22, height: 22)
                    .foregroundStyle(.white)
                    .background(Theme.playerColor(e.player),
                                in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Recent results: " + entries.map(\.initial).joined(separator: ", "))
    }
}
