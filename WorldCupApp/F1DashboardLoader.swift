import Foundation

// MARK: - Loader Result

/// Holds all data loaded from the three F1 data sources.
struct F1DashboardData: Sendable {
    var nextRace: F1Race?
    var lastResult: F1RaceResult?
    var driverStandings: [F1DriverStanding] = []
    var constructorStandings: [F1ConstructorStanding] = []
    var seasonRaces: [F1Race] = []
    var fiaDocuments: [FIADocument] = []
    var liveEventName: String = ""
    var liveDocCount: Int = 0
    var recentSessions: [F1OpenF1Session] = []
    var errorMessage: String?
}

// MARK: - Loader

/// Encapsulates the data loading logic for the F1 dashboard.
/// Accepts service type references so tests can inject mock services.
///
/// Usage:
/// ```swift
/// let loader = F1DashboardLoader()
/// let data = await loader.loadAll()
/// ```
@MainActor
final class F1DashboardLoader {

    private let f1ServiceType: F1ServiceProtocol.Type
    private let livePulseServiceType: F1LivePulseServiceProtocol.Type
    private let openF1ServiceType: F1OpenF1ServiceProtocol.Type

    /// The current OpenF1 year setting.
    var openF1Year: Int = 2026

    /// When false, OpenF1 data is skipped entirely (returns empty array).
    var openF1Enabled: Bool = true

    init(
        f1ServiceType: F1ServiceProtocol.Type = F1Service.self,
        livePulseServiceType: F1LivePulseServiceProtocol.Type = F1LivePulseService.self,
        openF1ServiceType: F1OpenF1ServiceProtocol.Type = F1OpenF1Service.self
    ) {
        self.f1ServiceType = f1ServiceType
        self.livePulseServiceType = livePulseServiceType
        self.openF1ServiceType = openF1ServiceType
    }

    /// Fires all 7 data requests in parallel, collects results independently,
    /// and returns a `F1DashboardData` with whatever succeeded.
    /// Only populates `errorMessage` if **every** source failed.
    func loadAll() async -> F1DashboardData {
        // Fire all requests in parallel
        async let nextTask = f1ServiceType.fetchNextRace()
        async let lastTask = f1ServiceType.fetchLastRaceResult()
        async let driversTask = f1ServiceType.fetchDriverStandings(year: nil)
        async let constructorsTask = f1ServiceType.fetchConstructorStandings(year: nil)
        async let racesTask = f1ServiceType.fetchCurrentSeason()
        async let docTask = livePulseServiceType.fetchFIADocumentsResponse()
        async let sessionsTask = openF1Enabled
            ? openF1ServiceType.fetchRaceSessions(year: openF1Year)
            : []

        // Collect results independently — one failure won't cascade
        var data = F1DashboardData()
        var successCount = 0

        do { data.nextRace = try await nextTask; successCount += 1 }
        catch { print("⚠️ f1api.dev (next race): \(error.localizedDescription)") }

        do { data.lastResult = try await lastTask; successCount += 1 }
        catch { print("⚠️ f1api.dev (last result): \(error.localizedDescription)") }

        do { data.driverStandings = try await driversTask; successCount += 1 }
        catch { print("⚠️ f1api.dev (driver standings): \(error.localizedDescription)") }

        do { data.constructorStandings = try await constructorsTask; successCount += 1 }
        catch { print("⚠️ f1api.dev (constructor standings): \(error.localizedDescription)") }

        do { data.seasonRaces = try await racesTask; successCount += 1 }
        catch { print("⚠️ f1api.dev (season races): \(error.localizedDescription)") }

        do {
            let docResponse = try await docTask
            data.fiaDocuments = docResponse.documents
            data.liveEventName = docResponse.event ?? ""
            data.liveDocCount = docResponse.documents.count
            successCount += 1
        } catch { print("⚠️ F1 Live Pulse: \(error.localizedDescription)") }

        do { data.recentSessions = try await sessionsTask; successCount += 1 }
        catch { print("⚠️ OpenF1: \(error.localizedDescription)") }

        if successCount == 0 {
            data.errorMessage = "Couldn't load F1 data. Check your internet connection and API keys."
        }

        return data
    }
}
