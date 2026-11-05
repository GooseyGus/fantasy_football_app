import SwiftUI

/// Each club's main and second kit colours, close enough to tell the clubs apart at a glance.
/// Keyed by FPL's three-letter short name. Includes clubs that may come up from the Championship.
struct ClubColors {
    /// The shirt.
    let primary: Color
    /// The trim, used for the club's letters on top of the shirt colour.
    let secondary: Color

    private init(_ primary: UInt32, _ secondary: UInt32) {
        self.primary = Color(hex: primary)
        self.secondary = Color(hex: secondary)
    }

    /// For a club that isn't in the list.
    static let unknown = ClubColors(primary: .card, secondary: .ink)

    private init(primary: Color, secondary: Color) {
        self.primary = primary
        self.secondary = secondary
    }

    static func of(_ club: String) -> ClubColors { all[club] ?? unknown }

    private static let all: [String: ClubColors] = [
        "ARS": .init(0xEF0107, 0xFFFFFF),
        "AVL": .init(0x670E36, 0x95BFE5),
        "BOU": .init(0xDA291C, 0x000000),
        "BRE": .init(0xE30613, 0xFFFFFF),
        "BHA": .init(0x0057B8, 0xFFFFFF),
        "BUR": .init(0x6C1D45, 0x99D6EA),
        "CHE": .init(0x034694, 0xFFFFFF),
        "COV": .init(0x59CBE8, 0x0B2240),
        "CRY": .init(0x1B458F, 0xC4122E),
        "EVE": .init(0x003399, 0xFFFFFF),
        "FUL": .init(0xFFFFFF, 0x000000),
        "HUL": .init(0xF5A12D, 0x000000),
        "IPS": .init(0x0044A9, 0xFFFFFF),
        "LEE": .init(0xFFFFFF, 0x1D428A),
        "LEI": .init(0x003090, 0xFDBE11),
        "LIV": .init(0xC8102E, 0xFFFFFF),
        "LUT": .init(0xF78F1E, 0x002D62),
        "MCI": .init(0x6CABDD, 0x1C2C5B),
        "MID": .init(0xE11B22, 0xFFFFFF),
        "MUN": .init(0xDA291C, 0xFBE122),
        "NEW": .init(0x241F20, 0xFFFFFF),
        "NFO": .init(0xDD0000, 0xFFFFFF),
        "NOR": .init(0xFFF200, 0x00A650),
        "SHU": .init(0xEE2737, 0xFFFFFF),
        "SOU": .init(0xD71920, 0xFFFFFF),
        "STK": .init(0xE03A3E, 0xFFFFFF),
        "SUN": .init(0xEB172B, 0xFFFFFF),
        "TOT": .init(0xFFFFFF, 0x132257),
        "WAT": .init(0xFBEE23, 0xED2127),
        "WBA": .init(0x122F67, 0xFFFFFF),
        "WHU": .init(0x7A263A, 0x1BB1E7),
        "WOL": .init(0xFDB913, 0x231F20),
    ]
}
