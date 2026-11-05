import SwiftUI

/// Asks for a team ID the first time, then shows that team from then on.
struct ContentView: View {
    /// 0 until a team has been chosen.
    @AppStorage("teamID") private var teamID = 0

    var body: some View {
        if teamID == 0 {
            TeamIDView { teamID = $0 }
        } else {
            MainView(teamID: teamID, onChangeTeam: { teamID = $0 }, onRemoveTeam: { teamID = 0 })
                // A new team starts from scratch.
                .id(teamID)
        }
    }
}

extension CoordinateSpaceProtocol where Self == NamedCoordinateSpace {
    /// The whole of Home and Account, where swipes are measured.
    static var swipeArea: Self { .named("swipeArea") }
}

/// Home and Account side by side: swipe between them, or tap the bar along the bottom.
///
/// Every sideways swipe, on either page, is handled here rather than by two scroll views inside each other.
/// A scroll view hangs on to touches until it has settled, so a quick second swipe would go to the wrong one.
/// Here each swipe is given to the gameweeks or the pages as it starts, even while the last one is still sliding.
private struct MainView: View {
    private enum Page: Int { case home, account }

    /// What the swipe in progress moves.
    private enum SwipeTarget { case pages, gameweeks, nothing }

    let onChangeTeam: (Int) -> Void
    let onRemoveTeam: () -> Void

    @State private var team: Team
    @Environment(\.scenePhase) private var scenePhase

    @State private var page = Page.home
    @State private var pageDrag: CGFloat = 0
    @State private var gameweek: Int?
    @State private var gameweekDrag: CGFloat = 0
    @State private var pitchFrame = CGRect.zero
    @State private var swipeTarget: SwipeTarget?

    private static let slide = Animation.spring(duration: 0.35, bounce: 0)

    init(teamID: Int, onChangeTeam: @escaping (Int) -> Void, onRemoveTeam: @escaping () -> Void) {
        _team = State(initialValue: Team(id: teamID))
        self.onChangeTeam = onChangeTeam
        self.onRemoveTeam = onRemoveTeam
    }

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            HStack(spacing: 0) {
                HomeView(team: team, selected: $gameweek, drag: gameweekDrag) { pitchFrame = $0 }
                    .frame(width: width)
                AccountView(team: team, onChangeTeam: onChangeTeam, onRemoveTeam: onRemoveTeam)
                    .frame(width: width)
            }
            .offset(x: -CGFloat(page.rawValue) * width + pageDrag)
            .contentShape(.rect)
            .gesture(swipe(width: width))
        }
        .coordinateSpace(.swipeArea)
        .background(Color.paper)
        .safeAreaInset(edge: .bottom, spacing: 0) { tabBar }
        .task { await team.start() }
        // Points change during a gameweek, so refresh whenever the app comes back.
        .onChange(of: scenePhase) {
            if scenePhase == .active { Task { await team.refresh() } }
        }
    }

    private func swipe(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 10, coordinateSpace: .swipeArea)
            .onChanged { value in
                let dx = value.translation.width
                // Dragging left moves forwards. With nothing that way, the drag resists.
                let step = dx < 0 ? 1 : -1
                if swipeTarget == nil { swipeTarget = target(for: value) }
                switch swipeTarget {
                case .pages:
                    pageDrag = Page(rawValue: page.rawValue + step) == nil ? dx / 3 : dx
                case .gameweeks:
                    guard let gameweek, let gameweeks = team.gameweeks else { return }
                    gameweekDrag = gameweeks.contains(gameweek + step) ? dx : dx / 3
                case .nothing, nil:
                    break
                }
            }
            .onEnded { value in
                // Where the swipe would carry on to, so a quick flick moves a page.
                let step = value.predictedEndTranslation.width < -width / 2 ? 1
                    : value.predictedEndTranslation.width > width / 2 ? -1 : 0
                withAnimation(Self.slide) {
                    switch swipeTarget {
                    case .pages:
                        page = Page(rawValue: page.rawValue + step) ?? page
                    case .gameweeks:
                        if let current = gameweek, team.gameweeks?.contains(current + step) == true {
                            gameweek = current + step
                        }
                    case .nothing, nil:
                        break
                    }
                    pageDrag = 0
                    gameweekDrag = 0
                }
                swipeTarget = nil
            }
    }

    /// A swipe on the pitch changes gameweek, unless there's no gameweek that way; then, like any other swipe, it changes page.
    private func target(for value: DragGesture.Value) -> SwipeTarget {
        let dx = value.translation.width
        guard abs(dx) > abs(value.translation.height) else { return .nothing }
        guard page == .home, pitchFrame.contains(value.startLocation),
              let gameweek, let gameweeks = team.gameweeks else { return .pages }
        return gameweeks.contains(gameweek + (dx < 0 ? 1 : -1)) ? .gameweeks : .pages
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            tab("Home", systemImage: "sportscourt", for: .home)
            tab("Account", systemImage: "person.crop.circle", for: .account)
        }
        .padding(.top, 6)
        .background(Color.paper)
    }

    private func tab(_ title: String, systemImage: String, for destination: Page) -> some View {
        Button {
            withAnimation(Self.slide) { page = destination }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: systemImage)
                    .font(.system(size: 22))
                Text(title)
                    .font(.din(.caption))
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .foregroundStyle(page == destination ? Color.ink : Color.ink.opacity(0.4))
        .accessibilityAddTraits(page == destination ? .isSelected : [])
    }
}

#Preview {
    ContentView()
}
