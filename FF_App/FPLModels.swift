import Foundation

// The parts of the FPL API's responses the app uses. Field names match the API's snake_case,
// which the decoder converts.

/// `bootstrap-static`: every player, club and gameweek in the season.
struct Bootstrap: Decodable {
    let events: [Event]
    let teams: [Club]
    let elements: [Player]
    let elementTypes: [Position]

    /// The gameweek in progress, or the last one if the season is over.
    var currentEvent: Event? {
        events.first(where: \.isCurrent) ?? events.last(where: \.finished)
    }
}

struct Event: Decodable {
    let id: Int
    let name: String
    let finished: Bool
    let isCurrent: Bool
}

struct Club: Decodable {
    let id: Int
    let name: String
    /// Three letters, e.g. ARS.
    let shortName: String
}

struct Player: Decodable {
    let id: Int
    let webName: String
    let team: Int
    /// 1 goalkeeper, 2 defender, 3 midfielder, 4 forward.
    let elementType: Int
    /// In tenths of a million, so 158 is £15.8m.
    let nowCost: Int
    /// a available, d doubtful, i injured, s suspended, u unavailable, n not in the squad.
    let status: String
    let news: String
    let chanceOfPlayingNextRound: Int?
}

struct Position: Decodable {
    let id: Int
    /// GKP, DEF, MID or FWD.
    let singularNameShort: String
}

/// `entry/{id}`: a manager's team.
struct Entry: Decodable, Identifiable {
    let id: Int
    let name: String
    let playerFirstName: String
    let playerLastName: String
    /// The manager's country, e.g. England.
    let playerRegionName: String?
    let summaryOverallPoints: Int
    let summaryOverallRank: Int?
    /// Points in the latest gameweek.
    let summaryEventPoints: Int?
    /// The first gameweek the team played.
    let startedEvent: Int?
    let currentEvent: Int?

    var managerName: String { "\(playerFirstName) \(playerLastName)" }
}

/// `entry/{id}/event/{gw}/picks`: the squad as it stood at that gameweek's deadline.
struct Picks: Decodable {
    struct Pick: Decodable {
        let element: Int
        /// 1–11 start, 12–15 are the bench in order.
        let position: Int
        /// 0 on the bench, 2 for the captain, 3 for a triple captain.
        let multiplier: Int
        let isCaptain: Bool
        let isViceCaptain: Bool
    }

    struct History: Decodable {
        let points: Int
        let totalPoints: Int
        /// In tenths of a million, like `Player.nowCost`.
        let bank: Int
        let eventTransfersCost: Int
    }

    let activeChip: String?
    let picks: [Pick]
    let entryHistory: History
}

/// `event/{gw}/live`: every player's points so far this gameweek.
struct Live: Decodable {
    struct Element: Decodable {
        struct Stats: Decodable {
            let totalPoints: Int
            let minutes: Int
        }

        let id: Int
        let stats: Stats
    }

    let elements: [Element]
}
