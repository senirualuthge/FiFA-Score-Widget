import Foundation

// MARK: - Lightweight F1 models for the widget target
// These exactly mirror the real f1api.dev JSON keys verified against live responses.

struct WidgetF1DriverStanding: Codable {
    let classificationId: Int?
    let driverId: String
    let teamId: String?
    let points: Int?
    let position: Int?
    let wins: Int?
    let driver: WidgetF1DriverInfo?

    var displayName: String {
        driver?.shortName ?? driver?.surname ?? driverId.capitalized
    }
    var teamDisplay: String { teamId?.capitalized ?? "" }
}

struct WidgetF1DriverInfo: Codable {
    let name: String?
    let surname: String?
    let shortName: String?
}

struct WidgetF1ConstructorStanding: Codable {
    let teamId: String
    let points: Int?
    let position: Int?
    let wins: Int?
    let team: WidgetF1TeamInfo?

    var displayName: String { team?.teamName ?? teamId.capitalized }
}

struct WidgetF1TeamInfo: Codable {
    let teamName: String?
}

// Race date lives inside schedule.race, not at root level
struct WidgetF1Race: Codable {
    let raceName: String?
    let schedule: WidgetF1RaceSchedule?
    let circuit: WidgetF1Circuit?

    var date: String? { schedule?.race?.date }

    var raceDate: Date? {
        guard let d = date else { return nil }
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f.date(from: d)
    }

    var raceDateString: String? {
        guard let d = raceDate else { return nil }
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: d)
    }

    var daysUntil: Int? {
        guard let d = raceDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: Date()),
                                               to: Calendar.current.startOfDay(for: d)).day
    }
}

struct WidgetF1RaceSchedule: Codable {
    let race: WidgetF1Session?
}

struct WidgetF1Session: Codable {
    let date: String?
    let time: String?
}

struct WidgetF1Circuit: Codable {
    let circuitName: String?
    let country: String?
    let city: String?
}

// MARK: - Decodable wrappers matching actual f1api.dev response keys

private struct DriverChampWrapper: Codable {
    let driversChampionship: [WidgetF1DriverStanding]
    enum CodingKeys: String, CodingKey {
        case driversChampionship = "drivers_championship"
    }
}

private struct ConstructorChampWrapper: Codable {
    let constructorsChampionship: [WidgetF1ConstructorStanding]
    enum CodingKeys: String, CodingKey {
        case constructorsChampionship = "constructors_championship"
    }
}

// /current  → { "races": [...] }
private struct RacesWrapper: Codable {
    let races: [WidgetF1Race]
}

// /current/next or /current/last  → { "race": [...] }   (array!)
private struct SingleRaceWrapper: Codable {
    let race: [WidgetF1Race]
}

// MARK: - Snapshot

struct F1WidgetSnapshot: Codable {
    let driverStandings: [WidgetF1DriverStanding]
    let constructorStandings: [WidgetF1ConstructorStanding]
    let nextRace: WidgetF1Race?
    let lastRace: WidgetF1Race?

    static let placeholder = F1WidgetSnapshot(
        driverStandings: [],
        constructorStandings: [],
        nextRace: nil,
        lastRace: nil
    )
}

// MARK: - Fetch service

enum F1WidgetService {
    private static let base = "https://f1api.dev/api"

    static func fetchSnapshot() async -> F1WidgetSnapshot {
        async let drivers    = fetchDrivers()
        async let constructs = fetchConstructors()
        async let nextRace   = fetchNext()
        async let lastRace   = fetchLast()

        let (d, c, n, l) = await (drivers, constructs, nextRace, lastRace)

        return F1WidgetSnapshot(
            driverStandings:      Array(d.prefix(5)),
            constructorStandings: Array(c.prefix(5)),
            nextRace: n,
            lastRace: l
        )
    }

    private static func fetchDrivers() async -> [WidgetF1DriverStanding] {
        guard let url = URL(string: "\(base)/current/drivers-championship"),
              let data = try? await URLSession.shared.data(from: url).0 else { return [] }
        return (try? JSONDecoder().decode(DriverChampWrapper.self, from: data))?.driversChampionship ?? []
    }

    private static func fetchConstructors() async -> [WidgetF1ConstructorStanding] {
        guard let url = URL(string: "\(base)/current/constructors-championship"),
              let data = try? await URLSession.shared.data(from: url).0 else { return [] }
        return (try? JSONDecoder().decode(ConstructorChampWrapper.self, from: data))?.constructorsChampionship ?? []
    }

    private static func fetchNext() async -> WidgetF1Race? {
        guard let url = URL(string: "\(base)/current/next"),
              let data = try? await URLSession.shared.data(from: url).0 else { return nil }
        return (try? JSONDecoder().decode(SingleRaceWrapper.self, from: data))?.race.first
    }

    private static func fetchLast() async -> WidgetF1Race? {
        guard let url = URL(string: "\(base)/current/last"),
              let data = try? await URLSession.shared.data(from: url).0 else { return nil }
        return (try? JSONDecoder().decode(SingleRaceWrapper.self, from: data))?.race.first
    }
}
