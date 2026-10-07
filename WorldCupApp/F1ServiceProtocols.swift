import Foundation

// MARK: - Service Protocols

/// Protocol for the f1api.dev service (free, no API key required).
protocol F1ServiceProtocol: Sendable {
    static func fetchNextRace() async throws -> F1Race?
    static func fetchLastRaceResult() async throws -> F1RaceResult?
    static func fetchDriverStandings(year: Int?) async throws -> [F1DriverStanding]
    static func fetchConstructorStandings(year: Int?) async throws -> [F1ConstructorStanding]
    static func fetchCurrentSeason() async throws -> [F1Race]
}

/// Protocol for the F1 Live Pulse RapidAPI service.
protocol F1LivePulseServiceProtocol: Sendable {
    static func fetchFIADocumentsResponse() async throws -> FIADocumentsResponse
}

/// Protocol for the OpenF1 service (free historical data).
protocol F1OpenF1ServiceProtocol: Sendable {
    static func fetchRaceSessions(year: Int) async throws -> [F1OpenF1Session]
}

// MARK: - Concrete Conformances

extension F1Service: F1ServiceProtocol {}
extension F1LivePulseService: F1LivePulseServiceProtocol {}
extension F1OpenF1Service: F1OpenF1ServiceProtocol {}
