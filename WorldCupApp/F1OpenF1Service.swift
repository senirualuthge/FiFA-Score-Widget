import Foundation

/// Service for fetching Formula 1 telemetry and lap data from OpenF1.
/// Historical data (2023 onwards) is **free and requires no API key**.
/// Live data during sessions requires a paid subscription.
enum F1OpenF1Service {

    private static let baseURL = "https://api.openf1.org/v1"

    // MARK: - Sessions

    /// Fetch race sessions for a given year.
    static func fetchRaceSessions(year: Int) async throws -> [F1OpenF1Session] {
        let data = try await request("/sessions?year=\(year)&session_name=Race")
        return try JSONDecoder().decode([F1OpenF1Session].self, from: data)
    }

    /// Fetch all sessions (practice, qualifying, race) for a given year.
    static func fetchAllSessions(year: Int) async throws -> [F1OpenF1Session] {
        let data = try await request("/sessions?year=\(year)")
        return try JSONDecoder().decode([F1OpenF1Session].self, from: data)
    }

    /// Get the latest/current session.
    static func fetchLatestSession() async throws -> [F1OpenF1Session] {
        let data = try await request("/sessions?session_key=latest")
        return try JSONDecoder().decode([F1OpenF1Session].self, from: data)
    }

    // MARK: - Drivers

    /// Fetch drivers participating in a session.
    static func fetchDrivers(sessionKey: Int) async throws -> [F1OpenF1Driver] {
        let data = try await request("/drivers?session_key=\(sessionKey)")
        return try JSONDecoder().decode([F1OpenF1Driver].self, from: data)
    }

    /// Fetch all drivers from the latest session.
    static func fetchLatestDrivers() async throws -> [F1OpenF1Driver] {
        let data = try await request("/drivers?session_key=latest")
        return try JSONDecoder().decode([F1OpenF1Driver].self, from: data)
    }

    // MARK: - Laps

    /// Fetch lap data for a specific session and driver.
    static func fetchLaps(sessionKey: Int, driverNumber: Int) async throws -> [F1Lap] {
        let data = try await request("/laps?session_key=\(sessionKey)&driver_number=\(driverNumber)")
        return try JSONDecoder().decode([F1Lap].self, from: data)
    }

    /// Fetch all laps for a session (all drivers).
    static func fetchAllLaps(sessionKey: Int) async throws -> [F1Lap] {
        let data = try await request("/laps?session_key=\(sessionKey)")
        return try JSONDecoder().decode([F1Lap].self, from: data)
    }

    // MARK: - Car Data (Telemetry)

    /// Fetch car telemetry for a specific session and driver.
    static func fetchCarData(sessionKey: Int, driverNumber: Int) async throws -> [F1CarData] {
        let data = try await request("/car_data?session_key=\(sessionKey)&driver_number=\(driverNumber)")
        return try JSONDecoder().decode([F1CarData].self, from: data)
    }

    /// Fetch car telemetry for a specific session, driver, and speed threshold.
    static func fetchCarData(sessionKey: Int, driverNumber: Int, minSpeed: Double) async throws -> [F1CarData] {
        let data = try await request("/car_data?session_key=\(sessionKey)&driver_number=\(driverNumber)&speed>=\(minSpeed)")
        return try JSONDecoder().decode([F1CarData].self, from: data)
    }

    // MARK: - Networking

    private static func request(_ path: String) async throws -> Data {
        guard let url = URL(string: baseURL + path) else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200...299).contains(http.statusCode) else {
            // Check for "No results found"
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: String],
               let detail = errorJson["detail"] {
                throw F1OpenF1Error.apiError(detail)
            }
            throw URLError(.badServerResponse)
        }

        return data
    }
}

enum F1OpenF1Error: LocalizedError {
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .apiError(let message):
            return "OpenF1: \(message)"
        }
    }
}
