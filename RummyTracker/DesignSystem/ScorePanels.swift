import SwiftUI

/// Dark slate head-to-head card. Generic over names + win counts. Used by the
/// Home hero and the Stats screen.
struct SlateFaceoffCard: View {
    let name1: String
    let wins1: Int
    let name2: String
    let wins2: Int
    var centerLabel: String? = nil
    var subtitle: String? = nil

    var body: some View {
        VStack(spacing: 10) {
            HStack(alignment: .bottom) {
                side(name: name1, wins: wins1, player: 1, align: .leading)
                Spacer(minLength: 8)
                if let centerLabel {
                    Text(centerLabel)
                        .font(.system(size: 10, weight: .bold)).tracking(2)
                        .foregroundStyle(.white.opacity(0.45))
                        .padding(.bottom, 14)
                }
                Spacer(minLength: 8)
                side(name: name2, wins: wins2, player: 2, align: .trailing)
            }
            if let subtitle {
                Text(subtitle).font(.system(size: 11)).foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Theme.slate, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func side(name: String, wins: Int, player: Int, align: HorizontalAlignment) -> some View {
        VStack(alignment: align, spacing: 2) {
            HStack(spacing: 5) {
                if player == 1 {
                    dot(player); nameText(name)
                } else {
                    nameText(name); dot(player)
                }
            }
            Text("\(wins)")
                .font(Theme.number(46))
                .foregroundStyle(Theme.playerColorOnSlate(player))
                .contentTransition(.numericText())
        }
    }

    private func dot(_ player: Int) -> some View {
        Circle().fill(Theme.playerColorOnSlate(player)).frame(width: 8, height: 8)
    }

    private func nameText(_ name: String) -> some View {
        Text(name).font(.system(size: 12, weight: .bold)).foregroundStyle(.white.opacity(0.85)).lineLimit(1)
    }
}

/// Live scoreboard panel for an in-progress / finished game: totals + race-to-target bars.
struct ScorePanel: View {
    let game: Game

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top) {
                column(name: game.player1Name, total: game.player1Total, player: 1)
                column(name: game.player2Name, total: game.player2Total, player: 2)
            }
            Text("FIRST TO \(game.targetScore)")
                .font(.system(size: 10, weight: .bold)).tracking(1.5)
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Theme.slate, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func column(name: String, total: Int, player: Int) -> some View {
        let accent = Theme.playerColorOnSlate(player)
        return VStack(spacing: 6) {
            HStack(spacing: 5) {
                Circle().fill(accent).frame(width: 7, height: 7)
                Text(name).font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.85)).lineLimit(1)
            }
            Text("\(total)")
                .font(Theme.number(40))
                .foregroundStyle(accent)
                .contentTransition(.numericText())
            // Clamp 0...target so negative totals don't break the bar.
            ProgressView(value: Double(max(0, min(total, game.targetScore))),
                         total: Double(game.targetScore))
                .tint(accent)
        }
        .frame(maxWidth: .infinity)
    }
}
