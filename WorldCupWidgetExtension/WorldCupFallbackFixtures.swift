import Foundation

/// Hardcoded schedule for the remainder of the 2026 World Cup knockout
/// stage (quarterfinals through the final). FIFA fixes these dates,
/// kickoff times, and venues well in advance — only the matchups are
/// still provisional ("Winner Match X") until each prior round finishes.
///
/// This exists as a safety net for two situations:
///   1. `football-data.org`'s free tier rate-limits or lags behind during
///      the tournament's business end, and there's no cached snapshot yet
///      to fall back on (e.g. very first widget install).
///   2. You want the widget to show *something* concrete while debugging
///      the network/cache path, instead of the empty `.placeholder`.
///
/// Update the `TODO` team names below once each round's participants are
/// confirmed — everything else (dates, times, venues) is fixed by FIFA
/// and shouldn't need to change.
enum WorldCupFallbackFixtures {

    /// All times below are UTC (ET converted to UTC; Eastern Daylight Time
    /// is UTC-4 in July, so e.g. 4:00 PM ET == 20:00 UTC).
    static let remainingMatches: [Match] = [

        // MARK: - Quarterfinals

        Match(
            id: 9001,
            utcDate: "2026-07-09T20:00:00Z",
            status: "SCHEDULED",
            matchday: nil,
            stage: "QUARTER_FINALS",
            group: nil,
            venue: "Gillette Stadium, Foxborough",
            homeTeam: .init(name: "France", shortName: "France", crest: nil),
            awayTeam: .init(name: "Morocco", shortName: "Morocco", crest: nil),
            score: .init(fullTime: .init(home: nil, away: nil))
        ),
        Match(
            id: 9002,
            utcDate: "2026-07-10T19:00:00Z",
            status: "SCHEDULED",
            matchday: nil,
            stage: "QUARTER_FINALS",
            group: nil,
            venue: "SoFi Stadium, Inglewood",
            homeTeam: .init(name: "Spain", shortName: "Spain", crest: nil),
            awayTeam: .init(name: "Belgium", shortName: "Belgium", crest: nil),
            score: .init(fullTime: .init(home: nil, away: nil))
        ),
        Match(
            id: 9003,
            utcDate: "2026-07-11T21:00:00Z",
            status: "SCHEDULED",
            matchday: nil,
            stage: "QUARTER_FINALS",
            group: nil,
            venue: "Hard Rock Stadium, Miami Gardens",
            homeTeam: .init(name: "Norway", shortName: "Norway", crest: nil),
            awayTeam: .init(name: "England", shortName: "England", crest: nil),
            score: .init(fullTime: .init(home: nil, away: nil))
        ),
        Match(
            id: 9004,
            utcDate: "2026-07-12T01:00:00Z",
            status: "SCHEDULED",
            matchday: nil,
            stage: "QUARTER_FINALS",
            group: nil,
            venue: "Arrowhead Stadium, Kansas City",
            homeTeam: .init(name: "Argentina", shortName: "Argentina", crest: nil),
            // TODO: replace once the Switzerland/Colombia Round of 16 winner is confirmed
            awayTeam: .init(name: "Winner Match 96", shortName: "TBD", crest: nil),
            score: .init(fullTime: .init(home: nil, away: nil))
        ),

        // MARK: - Semifinals

        Match(
            id: 9005,
            utcDate: "2026-07-14T19:00:00Z",
            status: "SCHEDULED",
            matchday: nil,
            stage: "SEMI_FINALS",
            group: nil,
            venue: "AT&T Stadium, Arlington",
            // TODO: replace with confirmed QF1/QF2 winners
            homeTeam: .init(name: "Winner Match 97", shortName: "TBD", crest: nil),
            awayTeam: .init(name: "Winner Match 98", shortName: "TBD", crest: nil),
            score: .init(fullTime: .init(home: nil, away: nil))
        ),
        Match(
            id: 9006,
            utcDate: "2026-07-15T19:00:00Z",
            status: "SCHEDULED",
            matchday: nil,
            stage: "SEMI_FINALS",
            group: nil,
            venue: "Mercedes-Benz Stadium, Atlanta",
            // TODO: replace with confirmed QF3/QF4 winners
            homeTeam: .init(name: "Winner Match 99", shortName: "TBD", crest: nil),
            awayTeam: .init(name: "Winner Match 100", shortName: "TBD", crest: nil),
            score: .init(fullTime: .init(home: nil, away: nil))
        ),

        // MARK: - Third place & Final

        Match(
            id: 9007,
            utcDate: "2026-07-18T21:00:00Z",
            status: "SCHEDULED",
            matchday: nil,
            stage: "THIRD_PLACE",
            group: nil,
            venue: "Hard Rock Stadium, Miami Gardens",
            // TODO: replace with confirmed semifinal losers
            homeTeam: .init(name: "Loser Match 101", shortName: "TBD", crest: nil),
            awayTeam: .init(name: "Loser Match 102", shortName: "TBD", crest: nil),
            score: .init(fullTime: .init(home: nil, away: nil))
        ),
        Match(
            id: 9008,
            utcDate: "2026-07-19T19:00:00Z",
            status: "SCHEDULED",
            matchday: nil,
            stage: "FINAL",
            group: nil,
            venue: "MetLife Stadium, East Rutherford",
            // TODO: replace with confirmed semifinal winners
            homeTeam: .init(name: "Winner Match 101", shortName: "TBD", crest: nil),
            awayTeam: .init(name: "Winner Match 102", shortName: "TBD", crest: nil),
            score: .init(fullTime: .init(home: nil, away: nil))
        ),
    ]

    /// Only the matches still ahead of `now` — handy for slotting straight
    /// into `WorldCupSnapshot.upcomingMatches`.
    static func upcoming(after now: Date = Date()) -> [Match] {
        remainingMatches.filter { ($0.kickoffDate ?? .distantPast) > now }
    }
}