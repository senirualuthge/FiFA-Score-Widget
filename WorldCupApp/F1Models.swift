import Foundation

// MARK: - API Response Wrappers
// These exactly mirror the real f1api.dev JSON keys (verified against live responses).

/// /current/drivers  → { "drivers": [...] }
struct F1DriversResponse: Codable {
    let drivers: [F1Driver]
}

/// /current/teams  → { "teams": [...] }
struct F1TeamsResponse: Codable {
    let teams: [F1Team]
}

/// /current/drivers-championship  → { "drivers_championship": [...] }
struct F1DriverChampionshipResponse: Codable {
    let driversChampionship: [F1DriverStanding]
    enum CodingKeys: String, CodingKey {
        case driversChampionship = "drivers_championship"
    }
}

/// /current/constructors-championship  → { "constructors_championship": [...] }
struct F1ConstructorChampionshipResponse: Codable {
    let constructorsChampionship: [F1ConstructorStanding]
    enum CodingKeys: String, CodingKey {
        case constructorsChampionship = "constructors_championship"
    }
}

/// /current  or  /{year}/{round}  → { "races": [...] }
struct F1RacesResponse: Codable {
    let races: [F1Race]
}

/// /current/next  or  /current/last  → { "race": [...] }   (array under "race"!)
struct F1SingleRaceResponse: Codable {
    let race: [F1Race]
}

/// /current/last/race  → { "races": { ...race object with results... } }  (object under "races"!)
struct F1LastRaceResultResponse: Codable {
    let races: F1RaceResult
}

/// /circuits  → { "circuits": [...] }
struct F1CircuitsResponse: Codable {
    let circuits: [F1Circuit]
}

// MARK: - Core Models

struct F1Driver: Codable, Identifiable {
    let driverId: String
    let name: String?
    let surname: String?
    let number: String?        // API returns Int OR String, handled as String via custom decode
    let shortName: String?
    let nationality: String?
    let birthday: String?
    let teamId: String?
    let url: String?

    var id: String { driverId }

    var fullName: String {
        [name, surname].compactMap { $0 }.joined(separator: " ")
    }

    var displayName: String {
        shortName ?? surname ?? fullName
    }

    // number comes back as Int from the API, coerce to String
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        driverId    = try c.decode(String.self, forKey: .driverId)
        name        = try c.decodeIfPresent(String.self, forKey: .name)
        surname     = try c.decodeIfPresent(String.self, forKey: .surname)
        shortName   = try c.decodeIfPresent(String.self, forKey: .shortName)
        nationality = try c.decodeIfPresent(String.self, forKey: .nationality)
        birthday    = try c.decodeIfPresent(String.self, forKey: .birthday)
        teamId      = try c.decodeIfPresent(String.self, forKey: .teamId)
        url         = try c.decodeIfPresent(String.self, forKey: .url)
        // number: try Int first (API's normal case), fall back to String
        if let n = try? c.decodeIfPresent(Int.self, forKey: .number) {
            number = String(n)
        } else {
            number = try c.decodeIfPresent(String.self, forKey: .number)
        }
    }

    enum CodingKeys: String, CodingKey {
        case driverId, name, surname, number, shortName, nationality, birthday, teamId, url
    }
}

struct F1Team: Codable, Identifiable {
    let teamId: String
    let teamName: String?
    let teamNationality: String?
    let firstAppeareance: Int?
    let constructorsChampionships: Int?
    let driversChampionships: Int?
    let url: String?

    var id: String { teamId }

    var displayName: String {
        teamName ?? teamId
    }
}

// MARK: - Driver Standing
// API: { driverId, teamId, points, position, wins, driver: { name, surname, shortName, ... } }

struct F1DriverStanding: Codable, Identifiable {
    let classificationId: Int?
    let driverId: String
    let teamId: String?
    let points: Int?
    let position: Int?
    let wins: Int?
    let driver: F1StandingDriverInfo?

    var id: String { driverId }

    var displayName: String {
        driver?.shortName ?? driver?.surname ?? driverId.capitalized
    }
    var fullName: String {
        [driver?.name, driver?.surname].compactMap { $0 }.joined(separator: " ")
    }
    var shortName: String? { driver?.shortName }
    var teamName: String? { teamId?.capitalized }
}

struct F1StandingDriverInfo: Codable {
    let name: String?
    let surname: String?
    let shortName: String?
    let nationality: String?
    let birthday: String?
    let number: Int?
    let url: String?
}

// MARK: - Constructor Standing
// API: { classificationId, teamId, points, position, wins, team: { teamName, ... } }

struct F1ConstructorStanding: Codable, Identifiable {
    let classificationId: Int?
    let teamId: String
    let points: Int?
    let position: Int?
    let wins: Int?
    let team: F1TeamStandingInfo?

    var id: String { teamId }

    var displayName: String {
        team?.teamName ?? teamId.capitalized
    }
}

struct F1TeamStandingInfo: Codable {
    let teamName: String?
    let country: String?
    let firstAppareance: Int?
    let constructorsChampionships: Int?
    let driversChampionships: Int?
    let url: String?
}

// MARK: - Race
// API: date/time are nested inside schedule.race, NOT at the race level.
// raceId is a String like "australian_2026", not Int.

struct F1Race: Codable, Identifiable {
    let raceId: String?         // "australian_2026" — now String
    let round: Int?
    let raceName: String?
    let schedule: F1RaceSchedule?   // date/time lives here
    let circuit: F1Circuit?
    let url: String?
    let laps: Int?
    let winner: F1RaceWinner?
    let teamWinner: F1TeamWinner?

    var id: String { raceId ?? "\(round ?? 0)" }

    var roundLabel: String {
        guard let round else { return "" }
        return "Round \(round)"
    }

    /// Convenience: race date from the nested schedule
    var date: String? { schedule?.race?.date }
    var time: String? { schedule?.race?.time }

    var raceDate: Date? {
        guard let d = date else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: d)
    }

    var raceDateString: String? {
        guard let date = raceDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    // Convenience pass-throughs for session schedule
    var fp1: F1Session?  { schedule?.fp1 }
    var fp2: F1Session?  { schedule?.fp2 }
    var fp3: F1Session?  { schedule?.fp3 }
    var qualy: F1Session? { schedule?.qualy }
    var sprintQualy: F1Session? { schedule?.sprintQualy }
    var sprintRace: F1Session?  { schedule?.sprintRace }
}

struct F1RaceSchedule: Codable {
    let race: F1Session?
    let qualy: F1Session?
    let fp1: F1Session?
    let fp2: F1Session?
    let fp3: F1Session?
    let sprintQualy: F1Session?
    let sprintRace: F1Session?
}

struct F1RaceWinner: Codable {
    let driverId: String?
    let name: String?
    let surname: String?
    let shortName: String?
}

struct F1TeamWinner: Codable {
    let teamId: String?
    let teamName: String?
}

struct F1Session: Codable {
    let date: String?
    let time: String?
}

// MARK: - Circuit

struct F1Circuit: Codable, Identifiable {
    let circuitId: String?
    let circuitName: String?
    let country: String?
    let city: String?
    let circuitLength: String?
    let lapRecord: String?
    let corners: Int?
    let firstParticipationYear: Int?
    let url: String?

    var id: String { circuitId ?? circuitName ?? UUID().uuidString }

    var location: String {
        [city, country].compactMap { $0 }.joined(separator: ", ")
    }
}

// MARK: - Race Results
// /current/last/race → { "races": { ...object with results array... } }

struct F1RaceResult: Codable, Identifiable {
    let raceId: String?       // String in real API
    let round: Int?
    let raceName: String?
    let date: String?
    let time: String?
    let circuit: F1Circuit?
    let results: [F1RaceResultEntry]?

    var id: String { raceId ?? "\(round ?? 0)" }
}

struct F1RaceResultEntry: Codable, Identifiable {
    let driver: F1ResultDriver?
    let team: F1ResultTeam?
    let points: Int?
    let time: String?
    let retired: String?    // API sends null or string, not bool
    let fastLap: String?

    // position comes back as a String ("1", "2" …) in the live API
    var positionRaw: String?
    var position: Int? { positionRaw.flatMap { Int($0) } }

    var id: String { "\(driver?.driverId ?? UUID().uuidString)-\(positionRaw ?? "0")" }

    enum CodingKeys: String, CodingKey {
        case driver, team, points, time, retired, fastLap
        case positionRaw = "position"
    }
}

struct F1ResultDriver: Codable {
    let driverId: String?
    let name: String?
    let surname: String?
    let shortName: String?
    let number: Int?
    let nationality: String?
}

struct F1ResultTeam: Codable {
    let teamId: String?
    let teamName: String?
    let nationality: String?
}

// MARK: - Search Response

struct F1SearchResponse<T: Codable>: Codable {
    let results: [T]
}
