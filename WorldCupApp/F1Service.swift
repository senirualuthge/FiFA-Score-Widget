import Foundation

/// Fetches Formula 1 data from f1api.dev (free, no API key required).
enum F1Service {

    private static let baseURL = "https://f1api.dev/api"

    // MARK: - Drivers

    static func fetchCurrentDrivers() async throws -> [F1Driver] {
        let data = try await request("/current/drivers")
        return try JSONDecoder().decode(F1DriversResponse.self, from: data).drivers
    }

    static func fetchDrivers(year: Int) async throws -> [F1Driver] {
        let data = try await request("/\(year)/drivers")
        return try JSONDecoder().decode(F1DriversResponse.self, from: data).drivers
    }

    static func searchDrivers(query: String) async throws -> [F1Driver] {
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return [] }
        let data = try await request("/drivers/search?q=\(encoded)")
        return try JSONDecoder().decode(F1SearchResponse<F1Driver>.self, from: data).results
    }

    static func fetchDriver(id: String) async throws -> F1Driver? {
        let data = try await request("/current/drivers/\(id)")
        return try? JSONDecoder().decode(F1Driver.self, from: data)
    }

    // MARK: - Teams

    static func fetchCurrentTeams() async throws -> [F1Team] {
        let data = try await request("/current/teams")
        return try JSONDecoder().decode(F1TeamsResponse.self, from: data).teams
    }

    static func fetchTeamDrivers(teamId: String, year: Int? = nil) async throws -> [F1Driver] {
        let path = year.map { "/\($0)/teams/\(teamId)/drivers" } ?? "/current/teams/\(teamId)/drivers"
        let data = try await request(path)
        return try JSONDecoder().decode(F1DriversResponse.self, from: data).drivers
    }

    static func searchTeams(query: String) async throws -> [F1Team] {
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return [] }
        let data = try await request("/teams/search?q=\(encoded)")
        return try JSONDecoder().decode(F1SearchResponse<F1Team>.self, from: data).results
    }

    // MARK: - Standings
    // Real API keys: "drivers_championship" and "constructors_championship"

    static func fetchDriverStandings(year: Int? = nil) async throws -> [F1DriverStanding] {
        let path = year.map { "/\($0)/drivers-championship" } ?? "/current/drivers-championship"
        let data = try await request(path)
        return try JSONDecoder().decode(F1DriverChampionshipResponse.self, from: data).driversChampionship
    }

    static func fetchConstructorStandings(year: Int? = nil) async throws -> [F1ConstructorStanding] {
        let path = year.map { "/\($0)/constructors-championship" } ?? "/current/constructors-championship"
        let data = try await request(path)
        return try JSONDecoder().decode(F1ConstructorChampionshipResponse.self, from: data).constructorsChampionship
    }

    // MARK: - Races
    // /current  → { "races": [...] }

    static func fetchCurrentSeason() async throws -> [F1Race] {
        let data = try await request("/current")
        return try JSONDecoder().decode(F1RacesResponse.self, from: data).races
    }

    static func fetchRace(year: Int, round: Int) async throws -> F1Race? {
        let data = try await request("/\(year)/\(round)")
        return try JSONDecoder().decode(F1RacesResponse.self, from: data).races.first
    }

    // /current/next  and  /current/last  → { "race": [...] }  (array under "race")

    static func fetchNextRace() async throws -> F1Race? {
        let data = try await request("/current/next")
        return try JSONDecoder().decode(F1SingleRaceResponse.self, from: data).race.first
    }

    static func fetchLastRace() async throws -> F1Race? {
        let data = try await request("/current/last")
        return try JSONDecoder().decode(F1SingleRaceResponse.self, from: data).race.first
    }

    // /current/last/race  → { "races": { ...object... } }  (object under "races")

    static func fetchLastRaceResult() async throws -> F1RaceResult? {
        let data = try await request("/current/last/race")
        return try JSONDecoder().decode(F1LastRaceResultResponse.self, from: data).races
    }

    // MARK: - Circuits

    static func fetchCircuits() async throws -> [F1Circuit] {
        let data = try await request("/circuits")
        return try JSONDecoder().decode(F1CircuitsResponse.self, from: data).circuits
    }

    static func searchCircuits(query: String) async throws -> [F1Circuit] {
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return [] }
        let data = try await request("/circuits/search?q=\(encoded)")
        return try JSONDecoder().decode(F1SearchResponse<F1Circuit>.self, from: data).results
    }

    // MARK: - Seasons

    static func fetchSeasons() async throws -> [Int] {
        let data = try await request("/seasons")
        return try JSONDecoder().decode([Int].self, from: data)
    }

    // MARK: - Networking

    private static func request(_ path: String) async throws -> Data {
        guard let url = URL(string: baseURL + path) else {
            throw URLError(.badURL)
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return data
    }

    // MARK: - RapidAPI (for future use when subscribed)

    static func fetchRapidAPI<T: Decodable>(
        host: String,
        path: String,
        as type: T.Type
    ) async throws -> T {
        guard let url = URL(string: "https://\(host)\(path)") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(host, forHTTPHeaderField: "x-rapidapi-host")
        request.setValue(Secrets.rapidAPIKey, forHTTPHeaderField: "x-rapidapi-key")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}
