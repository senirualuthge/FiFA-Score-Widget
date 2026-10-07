import Foundation

// MARK: - API Response Models (football-data.org v4)

struct MatchesResponse: Codable {
    let matches: [Match]
}

struct Match: Codable, Identifiable {
    let id: Int
    let utcDate: String
    let status: String
    let matchday: Int?
    let stage: String?
    let group: String?
    let venue: String?
    let homeTeam: Team
    let awayTeam: Team
    let score: Score

    struct Team: Codable {
        let name: String?
        let shortName: String?
        let crest: String?

        /// Best available display name, falling back to "TBD" for
        /// future-stage matches where the team hasn't been determined yet.
        var displayName: String {
            shortName ?? name ?? "TBD"
        }
    }

    struct Score: Codable {
        /// The API returns `null` for the entire `fullTime` object when a match
        /// hasn't started yet, or for certain edge statuses (POSTPONED, CANCELED,
        /// AWARDED). Making this optional prevents the entire match — and therefore
        /// the whole `MatchesResponse` — from silently failing to decode.
        let fullTime: FullTime?
        struct FullTime: Codable {
            let home: Int?
            let away: Int?
        }
    }

    var displayScore: String {
        guard status == "IN_PLAY" || status == "PAUSED" || status == "FINISHED" else {
            return "vs"
        }
        guard let fullTime = score.fullTime else { return "- vs -" }
        let h = fullTime.home.map(String.init) ?? "-"
        let a = fullTime.away.map(String.init) ?? "-"
        return "\(h) - \(a)"
    }

    var isLive: Bool {
        status == "IN_PLAY" || status == "PAUSED"
    }

    var isFinished: Bool {
        status == "FINISHED" || status == "AWARDED"
    }

    /// Parses `utcDate` robustly. football-data.org normally returns
    /// "2026-07-12T15:00:00Z", but some responses (and other ISO8601
    /// producers in general) include fractional seconds, e.g.
    /// "2026-07-12T15:00:00.000Z" — plain `ISO8601DateFormatter()` fails
    /// to parse those and silently returns nil, which was previously
    /// cascading into every downstream label (date/time/meta) going blank
    /// with no error. This tries both formats before giving up.
    var kickoffDate: Date? {
        let parsers: [ISO8601DateFormatter] = [
            { let f = ISO8601DateFormatter(); f.formatOptions = [.withInternetDateTime]; return f }(),
            { let f = ISO8601DateFormatter(); f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]; return f }(),
            { let f = ISO8601DateFormatter(); f.formatOptions = [.withInternetDateTime, .withDashSeparatorInDate]; return f }()
        ]
        
        for parser in parsers {
            if let date = parser.date(from: utcDate) {
                return date
            }
        }
        return nil
    }

    /// Short local time, e.g. "3:00 PM" — nil if the date can't be parsed.
    var kickoffTimeString: String? {
        guard let date = kickoffDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    /// Short local date, e.g. "Jul 8" — nil if the date can't be parsed.
    var kickoffDateString: String? {
        guard let date = kickoffDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    /// Combined "date, time · venue" label for upcoming fixtures, e.g.
    /// "Jul 12, 3:00 PM · Estadio Azteca". Omits whichever pieces are
    /// unavailable (venue is frequently nil on football-data.org's free
    /// tier until close to matchday) rather than showing a placeholder.
    var kickoffMetaLabel: String? {
        let parts = [kickoffDateTimeString, venue].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    /// Compact version for widgets — date + time only, no venue, so it
    /// never overflows a narrow row. e.g. "Jul 12, 3:00 PM"
    var shortMetaLabel: String? { kickoffDateTimeString }

    private var kickoffDateTimeString: String? {
        switch (kickoffDateString, kickoffTimeString) {
        case let (d?, t?): return "\(d), \(t)"
        case let (d?, nil): return d
        case let (nil, t?): return t
        default: return nil
        }
    }

    /// e.g. "Group A" or "Quarter-Finals" — falls back gracefully if either piece is missing.
    var stageLabel: String? {
        let friendlyStage = stage?
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
        switch (friendlyStage, group) {
        case let (stage?, group?): return "\(group.capitalized) · \(stage)"
        case let (stage?, nil): return stage
        case let (nil, group?): return group.capitalized
        default: return nil
        }
    }
}

struct StandingsResponse: Codable {
    let standings: [StandingGroup]
}

struct StandingGroup: Codable {
    let group: String?
    let table: [StandingRow]
}

struct StandingRow: Codable, Identifiable {
    var id: String { team.name ?? UUID().uuidString }
    let position: Int
    let team: Team
    let playedGames: Int
    let won: Int
    let draw: Int
    let lost: Int
    let points: Int
    let goalsFor: Int?
    let goalsAgainst: Int?
    let goalDifference: Int?
    var groupName: String?

    struct Team: Codable {
        let name: String?
        let shortName: String?

        var displayName: String {
            shortName ?? name ?? "TBD"
        }
    }
}

// MARK: - Widget-facing simplified model

/// `Codable` so it can be cached (see `WorldCupService`'s snapshot cache) —
/// this is what lets the widget keep showing its last-known-good data
/// instead of going blank when a single fetch fails (e.g. hitting
/// football-data.org's rate limit).
struct WorldCupSnapshot: Codable {
    let liveMatches: [Match]
    let recentMatches: [Match]
    let upcomingMatches: [Match]
    let topStandings: [StandingRow]
    let lastUpdated: Date

    static let placeholder = WorldCupSnapshot(
        liveMatches: [],
        recentMatches: [],
        upcomingMatches: [],
        topStandings: [],
        lastUpdated: Date()
    )
}

// MARK: - Match detail (venue/stage + lineups, for the main app)

/// Fuller single-match payload from GET /v4/matches/{id}.
/// NOTE: `homeTeam.formation` / `homeTeam.lineup` are only populated on
/// football-data.org plans that include the "deep data" lineup add-on.
/// On the free tier these will simply be nil/empty, which the views below
/// handle gracefully.
struct MatchDetail: Codable {
    let id: Int
    let utcDate: String
    let status: String
    let matchday: Int?
    let stage: String?
    let group: String?
    let venue: String?
    let homeTeam: DetailedTeam
    let awayTeam: DetailedTeam

    struct DetailedTeam: Codable {
        let name: String?
        let shortName: String?
        let crest: String?
        let formation: String?
        let lineup: [LineupPlayer]?

        var displayName: String { shortName ?? name ?? "TBD" }
    }
}

struct LineupPlayer: Codable, Identifiable {
    let id: Int
    let name: String
    let position: String?
    let shirtNumber: Int?
}

// MARK: - Team squad (for player detail screens in the main app)

/// GET /v4/teams/{id} response — includes the full squad roster.
/// Unlike `MatchDetail.lineup`, this carries each player's nationality,
/// which is what the "team / country / position" detail view needs.
struct TeamDetail: Codable {
    let id: Int
    let name: String?
    let shortName: String?
    let crest: String?
    let squad: [SquadPlayer]?

    var displayName: String { shortName ?? name ?? "Unknown Team" }
}

struct SquadPlayer: Codable, Identifiable {
    let id: Int
    let name: String
    let position: String?
    let nationality: String?
    let dateOfBirth: String?

    /// e.g. "Forward" — falls back to a neutral label if the API omits it.
    var positionLabel: String { position ?? "Unknown position" }

    /// e.g. "Argentina" — falls back to a neutral label if the API omits it.
    var nationalityLabel: String { nationality ?? "Unknown country" }
}

/// GET /v4/competitions/WC/teams response — every squad in the tournament
/// in one call, so the main app doesn't need one request per team.
struct CompetitionTeamsResponse: Codable {
    let teams: [TeamDetail]
}

// MARK: - Formation layout

/// Maps a formation string like "4-3-3" plus an ordered lineup (goalkeeper
/// first, then defenders/midfielders/forwards in the order football-data.org
/// returns them) to normalized (0...1, 0...1) coordinates on a pitch, so a
/// SwiftUI view can place a chip per player without needing raw x/y data
/// from the API (which football-data.org doesn't provide).
enum FormationLayout {

    struct PlacedPlayer: Identifiable {
        let id: Int
        let player: LineupPlayer
        /// x: 0 = left touchline, 1 = right touchline
        /// y: 0 = own goal line, 1 = opponent's goal line
        let x: Double
        let y: Double
    }

    static func place(_ lineup: [LineupPlayer], formation: String?) -> [PlacedPlayer] {
        guard !lineup.isEmpty else { return [] }

        // Parse "4-3-3" -> [4, 3, 3]. Fall back to a generic back-to-front
        // spread if the formation string is missing or malformed.
        let rowSizes: [Int]
        if let formation,
           let parsed = parseFormation(formation),
           parsed.reduce(0, +) == lineup.count - 1 {
            rowSizes = parsed
        } else {
            // Unknown formation: spread everyone but the keeper across
            // up to 4 evenly-sized rows.
            let outfield = lineup.count - 1
            let rows = min(4, max(1, outfield / 3))
            let base = outfield / rows
            var remainder = outfield % rows
            rowSizes = (0..<rows).map { _ in
                let extra = remainder > 0 ? 1 : 0
                remainder -= extra
                return base + extra
            }
        }

        var placed: [PlacedPlayer] = []
        var cursor = 0

        // Goalkeeper sits alone near y = 0.05 (own goal line).
        if let keeper = lineup.first {
            placed.append(PlacedPlayer(id: keeper.id, player: keeper, x: 0.5, y: 0.06))
            cursor = 1
        }

        // Remaining rows spread from defense (y ~0.25) to attack (y ~0.9).
        let rowCount = rowSizes.count
        for (rowIndex, size) in rowSizes.enumerated() {
            guard size > 0 else { continue }
            let y = rowCount == 1 ? 0.5 : 0.25 + (0.65 * Double(rowIndex) / Double(rowCount - 1))
            for slot in 0..<size {
                guard cursor < lineup.count else { break }
                let x = size == 1 ? 0.5 : 0.12 + (0.76 * Double(slot) / Double(size - 1))
                placed.append(PlacedPlayer(id: lineup[cursor].id, player: lineup[cursor], x: x, y: y))
                cursor += 1
            }
        }

        return placed
    }

    private static func parseFormation(_ formation: String) -> [Int]? {
        let parts = formation.split(separator: "-").compactMap { Int($0) }
        return parts.isEmpty ? nil : parts
    }
}