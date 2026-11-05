import SwiftUI

/// The team in formation for one gameweek at a time. Swipe left and right on it for other gameweeks.
/// The swipes themselves are handled by `MainView`, which also swipes between Home and Account.
struct HomeView: View {
    let team: Team
    /// The gameweek on screen.
    @Binding var selected: Int?
    /// How far the pitch is being dragged sideways, in points.
    let drag: CGFloat
    /// Called with where the pitch is in `.swipeArea`, so swipes there can be told apart.
    let onPitchFrame: (CGRect) -> Void

    var body: some View {
        Group {
            if let gameweeks = team.gameweeks {
                VStack(spacing: 10) {
                    header(gameweeks)
                    // Only as tall as the pitch: swipes here change gameweek, and swipes
                    // anywhere else move between Home and Account.
                    pager(gameweeks, selected: selected ?? gameweeks.upperBound)
                        .onGeometryChange(for: CGRect.self, of: { $0.frame(in: .swipeArea) }, action: onPitchFrame)
                    Spacer(minLength: 0)
                }
                .padding(.top, 8)
                .padding(.bottom, 12)
                .onAppear {
                    if selected.map(gameweeks.contains) != true { selected = gameweeks.upperBound }
                }
            } else if let error = team.error {
                ContentUnavailableView {
                    Label("Couldn't load your team", systemImage: "wifi.exclamationmark")
                } description: {
                    Text(error)
                } actions: {
                    Button("Try again") { Task { await team.start() } }
                }
            } else {
                ProgressView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.paper)
    }

    /// "GAMEWEEK 9", with arrows to step through the gameweeks.
    private func header(_ gameweeks: ClosedRange<Int>) -> some View {
        let gameweek = selected ?? gameweeks.upperBound
        return HStack {
            step("Previous gameweek", systemImage: "chevron.left", to: gameweek - 1, in: gameweeks)
            Spacer()
            Text("GAMEWEEK \(gameweek)")
                .font(.din(.headline))
                .tracking(1.5)
                .contentTransition(.numericText())
            Spacer()
            step("Next gameweek", systemImage: "chevron.right", to: gameweek + 1, in: gameweeks)
        }
        .padding(.horizontal, 12)
    }

    private func step(_ title: String, systemImage: String, to gameweek: Int, in gameweeks: ClosedRange<Int>) -> some View {
        Button(title, systemImage: systemImage) {
            withAnimation { selected = gameweek }
        }
        .labelStyle(.iconOnly)
        .font(.din(.headline))
        .foregroundStyle(Color.soft)
        .frame(width: 44, height: 44)
        .disabled(!gameweeks.contains(gameweek))
        .opacity(gameweeks.contains(gameweek) ? 1 : 0.25)
    }

    /// The gameweeks side by side, slid along to the selected one.
    private func pager(_ gameweeks: ClosedRange<Int>, selected: Int) -> some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            HStack(spacing: 0) {
                ForEach(Array(gameweeks), id: \.self) { gameweek in
                    Group {
                        // Only the pages near the one on screen are drawn, so they're ready to swipe to.
                        if abs(gameweek - selected) <= 2 {
                            GameweekPage(team: team, gameweek: gameweek)
                                .padding(.horizontal, 12)
                        } else {
                            Color.clear
                        }
                    }
                    .frame(width: width)
                }
            }
            .offset(x: -CGFloat(selected - gameweeks.lowerBound) * width + drag)
        }
        .frame(height: Pitch.height)
        .clipped()
    }
}

/// One gameweek's lineup, loaded when it's first shown.
private struct GameweekPage: View {
    let team: Team
    let gameweek: Int

    var body: some View {
        Group {
            switch team.pages[gameweek] {
            case .loaded(let lineup):
                Pitch(lineup: lineup)
            case .failed(let error):
                VStack(spacing: 12) {
                    Text(error)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                    Button("Try again") { Task { await team.load(gameweek) } }
                }
                .padding()
            case .loading, nil:
                ProgressView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task { await team.load(gameweek) }
    }
}

/// One rounded box: a row per position for the starting eleven, then the bench.
private struct Pitch: View {
    let lineup: Team.Lineup

    private static let positions = ["GKP", "DEF", "MID", "FWD"]
    /// The most players a row can hold. Every box is sized so this many fit side by side.
    private static let mostInRow = 5
    private static let gap: CGFloat = 4
    private static let inset: CGFloat = 6
    private static let dividerHeight: CGFloat = 14

    /// Four rows of starters, the divider and the bench, so the pager can be exactly this tall.
    static let height = 2 * inset + 5 * PlayerTile.height + 5 * gap + dividerHeight

    @State private var width: CGFloat = 0

    var body: some View {
        let tileWidth = max(0, (width - 2 * Self.inset - CGFloat(Self.mostInRow - 1) * Self.gap) / CGFloat(Self.mostInRow))
        VStack(spacing: Self.gap) {
            ForEach(Self.positions, id: \.self) { position in
                row(lineup.starters.filter { $0.position == position }, tileWidth: tileWidth)
            }
            benchDivider
            row(lineup.bench, tileWidth: tileWidth)
        }
        .padding(Self.inset)
        .frame(maxWidth: .infinity)
        .onGeometryChange(for: CGFloat.self, of: \.size.width) { width = $0 }
        .background(Color.card, in: .rect(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.ink.opacity(0.2), lineWidth: 1.5)
        }
    }

    private var benchDivider: some View {
        Rectangle()
            .fill(Color.ink.opacity(0.15))
            .frame(height: 1)
            .overlay {
                Text("BENCH")
                    .font(.custom(Font.dinName, fixedSize: 10))
                    .tracking(1.5)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .background(Color.card)
            }
            .frame(height: Self.dividerHeight)
    }

    private func row(_ members: [Team.Member], tileWidth: CGFloat) -> some View {
        HStack(spacing: Self.gap) {
            ForEach(members) { PlayerTile(member: $0, width: tileWidth) }
        }
        .frame(maxWidth: .infinity)
    }
}

/// A player's box: name on top, then their club's tag and points. Every box is the same size;
/// names too long for it end in an ellipsis.
private struct PlayerTile: View {
    let member: Team.Member
    let width: CGFloat

    static let height: CGFloat = 44

    /// The bench didn't count, so show what they scored rather than nothing.
    private var isBenched: Bool { member.multiplier == 0 }

    var body: some View {
        let colors = ClubColors.of(member.club)
        VStack(spacing: 3) {
            // Fixed sizes rather than text styles, so the boxes keep their size.
            // At 12pt about 94% of names fit on a 6.3" iPhone.
            Text(member.name)
                .font(.custom(Font.dinName, fixedSize: 12))
                .truncationMode(.tail)
            HStack(spacing: 5) {
                Text(member.club)
                    .font(.custom(Font.dinName, fixedSize: 9))
                    .foregroundStyle(colors.secondary)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1.5)
                    .background(colors.primary, in: .capsule)
                    .overlay { Capsule().strokeBorder(Color.ink.opacity(0.25), lineWidth: 0.5) }
                Text("\(isBenched ? member.points : member.countedPoints)")
                    .font(.custom(Font.dinName, fixedSize: 15))
            }
        }
        .lineLimit(1)
        .padding(.horizontal, 3)
        .frame(width: width, height: Self.height)
        .background(Color.paper.opacity(0.55), in: .rect(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.ink.opacity(0.1), lineWidth: 1)
        }
    }
}
