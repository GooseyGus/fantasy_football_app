import Foundation

/// A manager's team: who they are, and their lineup in each gameweek, loaded as each one is looked at.
@Observable
final class Team {
    struct Member: Identifiable {
        let id: Int
        let name: String
        /// Three letters, e.g. ARS.
        let club: String
        /// GKP, DEF, MID or FWD.
        let position: String
        /// Gameweek points before the captain's multiplier.
        let points: Int
        /// 0 on the bench, 2 for the captain, 3 for a triple captain.
        let multiplier: Int

        /// What the player scored for the team: doubled for the captain, nothing on the bench.
        var countedPoints: Int { points * multiplier }
    }

    struct Lineup {
        let starters: [Member]
        let bench: [Member]
    }

    enum Page {
        case loading
        case loaded(Lineup)
        case failed(String)
    }

    let id: Int
    private(set) var entry: Entry?
    /// The gameweeks there's a lineup for: from the manager's first to the one in progress.
    private(set) var gameweeks: ClosedRange<Int>?
    private(set) var pages: [Int: Page] = [:]
    /// Why the team couldn't be loaded at all.
    private(set) var error: String?

    private let client = FPLClient()
    /// Every player and club, for turning a lineup's IDs into names.
    private var bootstrap: Bootstrap?

    init(id: Int) { self.id = id }

    /// Loads the team's details and works out which gameweeks there are. Safe to call again to refresh.
    func start() async {
        do {
            async let bootstrapCall = client.bootstrap()
            async let entryCall = client.entry(id)
            let (bootstrap, entry) = try await (bootstrapCall, entryCall)
            guard let current = bootstrap.currentEvent?.id else {
                error = "The season hasn't started yet."
                return
            }
            self.bootstrap = bootstrap
            self.entry = entry
            gameweeks = min(entry.startedEvent ?? 1, current)...current
            error = nil
        } catch is CancellationError {
        } catch {
            // Keep what's showing if a refresh fails; only report it if there's nothing to show.
            if entry == nil { self.error = error.localizedDescription }
        }
    }

    /// Loads a gameweek's lineup, unless it's already loaded and `refresh` is false.
    func load(_ gameweek: Int, refresh: Bool = false) async {
        guard let bootstrap else { return }
        let wasLoaded = if case .loaded = pages[gameweek] { true } else { false }
        if wasLoaded, !refresh { return }
        if !wasLoaded { pages[gameweek] = .loading }
        do {
            pages[gameweek] = .loaded(try await lineup(gameweek, bootstrap: bootstrap))
        } catch is CancellationError {
            // Swiped away before it finished; it loads again when it comes back.
            if !wasLoaded { pages[gameweek] = nil }
        } catch {
            if !wasLoaded { pages[gameweek] = .failed(error.localizedDescription) }
        }
    }

    /// Refreshes the team and the gameweek in progress, whose points may have changed.
    func refresh() async {
        await start()
        if let current = gameweeks?.upperBound {
            await load(current, refresh: true)
        }
    }

    private func lineup(_ gameweek: Int, bootstrap: Bootstrap) async throws -> Lineup {
        async let picksCall = client.picks(id, gameweek: gameweek)
        async let liveCall = client.live(gameweek: gameweek)
        let (picks, live) = try await (picksCall, liveCall)

        let players = Dictionary(uniqueKeysWithValues: bootstrap.elements.map { ($0.id, $0) })
        let clubs = Dictionary(uniqueKeysWithValues: bootstrap.teams.map { ($0.id, $0.shortName) })
        let positions = Dictionary(uniqueKeysWithValues: bootstrap.elementTypes.map { ($0.id, $0.singularNameShort) })
        let points = Dictionary(uniqueKeysWithValues: live.elements.map { ($0.id, $0.stats.totalPoints) })

        let members = picks.picks.sorted { $0.position < $1.position }.compactMap { pick -> Member? in
            guard let player = players[pick.element] else { return nil }
            return Member(
                id: player.id,
                name: player.webName,
                club: clubs[player.team] ?? "",
                position: positions[player.elementType] ?? "",
                points: points[player.id] ?? 0,
                multiplier: pick.multiplier
            )
        }
        return Lineup(starters: Array(members.prefix(11)), bench: Array(members.dropFirst(11)))
    }
}
