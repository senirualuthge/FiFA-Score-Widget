import XCTest
@testable import WorldCupApp

// MARK: - Mock Services

/// Mock f1api.dev service — each call returns the pre-configured result or throws an error.
final class MockF1Service: F1ServiceProtocol {

    nonisolated(unsafe) static var nextRaceResult: F1Race?
    nonisolated(unsafe) static var nextRaceError: Error?
    static func fetchNextRace() async throws -> F1Race? {
        if let error = nextRaceError { throw error }
        return nextRaceResult
    }

    nonisolated(unsafe) static var lastResultResult: F1RaceResult?
    nonisolated(unsafe) static var lastResultError: Error?
    static func fetchLastRaceResult() async throws -> F1RaceResult? {
        if let error = lastResultError { throw error }
        return lastResultResult
    }

    nonisolated(unsafe) static var driverStandingsResult: [F1DriverStanding] = []
    nonisolated(unsafe) static var driverStandingsError: Error?
    static func fetchDriverStandings(year: Int?) async throws -> [F1DriverStanding] {
        if let error = driverStandingsError { throw error }
        return driverStandingsResult
    }

    nonisolated(unsafe) static var constructorStandingsResult: [F1ConstructorStanding] = []
    nonisolated(unsafe) static var constructorStandingsError: Error?
    static func fetchConstructorStandings(year: Int?) async throws -> [F1ConstructorStanding] {
        if let error = constructorStandingsError { throw error }
        return constructorStandingsResult
    }

    nonisolated(unsafe) static var currentSeasonResult: [F1Race] = []
    nonisolated(unsafe) static var currentSeasonError: Error?
    static func fetchCurrentSeason() async throws -> [F1Race] {
        if let error = currentSeasonError { throw error }
        return currentSeasonResult
    }

    /// Reset all mock state to defaults.
    static func reset() {
        nextRaceResult = nil
        nextRaceError = nil
        lastResultResult = nil
        lastResultError = nil
        driverStandingsResult = []
        driverStandingsError = nil
        constructorStandingsResult = []
        constructorStandingsError = nil
        currentSeasonResult = []
        currentSeasonError = nil
    }
}

/// Mock F1 Live Pulse service.
final class MockLivePulseService: F1LivePulseServiceProtocol {

    nonisolated(unsafe) static var documentsResult = FIADocumentsResponse(documents: [], event: nil, meeting_index: nil)
    nonisolated(unsafe) static var documentsError: Error?
    static func fetchFIADocumentsResponse() async throws -> FIADocumentsResponse {
        if let error = documentsError { throw error }
        return documentsResult
    }

    static func reset() {
        documentsResult = FIADocumentsResponse(documents: [], event: nil, meeting_index: nil)
        documentsError = nil
    }
}

/// Mock OpenF1 service.
final class MockOpenF1Service: F1OpenF1ServiceProtocol {

    nonisolated(unsafe) static var sessionsResult: [F1OpenF1Session] = []
    nonisolated(unsafe) static var sessionsError: Error?
    static func fetchRaceSessions(year: Int) async throws -> [F1OpenF1Session] {
        if let error = sessionsError { throw error }
        return sessionsResult
    }

    static func reset() {
        sessionsResult = []
        sessionsError = nil
    }
}

// MARK: - Test Error

/// A simple identifiable error for testing failure scenarios.
struct TestError: Error, CustomStringConvertible {
    let message: String
    var description: String { message }

    static let network = TestError(message: "Network error")
    static let rateLimit = TestError(message: "Rate limited")
    static let decoding = TestError(message: "Decoding failed")
}

// MARK: - Test Suite

@MainActor
final class F1DashboardLoaderTests: XCTestCase {

    var loader: F1DashboardLoader!

    override func setUp() async throws {
        try await super.setUp()
        // Reset all mocks before each test
        await MainActor.run {
            MockF1Service.reset()
            MockLivePulseService.reset()
            MockOpenF1Service.reset()
            // Create loader with mock services
            loader = F1DashboardLoader(
                f1ServiceType: MockF1Service.self,
                livePulseServiceType: MockLivePulseService.self,
                openF1ServiceType: MockOpenF1Service.self
            )
            loader.openF1Enabled = true
            loader.openF1Year = 2026
        }
    }

    override func tearDown() async throws {
        await MainActor.run {
            loader = nil
            MockF1Service.reset()
            MockLivePulseService.reset()
            MockOpenF1Service.reset()
        }
        try await super.tearDown()
    }

    // MARK: - All Services Succeed

    func testAllSourcesSucceed() async {
        // Given: All services return valid data
        await configureAllSuccess()

        // When: Loading all data
        let data = await loader.loadAll()

        // Then: All data should be populated
        XCTAssertNotNil(data.nextRace)
        XCTAssertNotNil(data.lastResult)
        XCTAssertEqual(data.driverStandings.count, 3)
        XCTAssertEqual(data.constructorStandings.count, 2)
        XCTAssertGreaterThan(data.seasonRaces.count, 0)
        XCTAssertEqual(data.fiaDocuments.count, 2)
        XCTAssertEqual(data.liveEventName, "Monaco Grand Prix")
        XCTAssertEqual(data.liveDocCount, 2)
        XCTAssertEqual(data.recentSessions.count, 1)
        XCTAssertNil(data.errorMessage)
    }

    // MARK: - Single Service Failures

    func testF1APIFails_LivePulseAndOpenF1Succeed() async {
        // Given: Only f1api.dev sources fail
        MockF1Service.nextRaceError = TestError.network
        MockF1Service.lastResultError = TestError.network
        MockF1Service.driverStandingsError = TestError.decoding
        MockF1Service.constructorStandingsError = TestError.rateLimit
        MockF1Service.currentSeasonError = TestError.network
        await configureLivePulseSuccess()
        await configureOpenF1Success()

        // When: Loading all data
        let data = await loader.loadAll()

        // Then: Live Pulse and OpenF1 data should load, f1api.dev data should be nil/empty
        XCTAssertNil(data.nextRace)
        XCTAssertNil(data.lastResult)
        XCTAssertTrue(data.driverStandings.isEmpty)
        XCTAssertTrue(data.constructorStandings.isEmpty)
        XCTAssertTrue(data.seasonRaces.isEmpty)
        XCTAssertEqual(data.fiaDocuments.count, 2)
        XCTAssertEqual(data.recentSessions.count, 1)
        XCTAssertNil(data.errorMessage) // Not all sources failed
    }

    func testLivePulseFails_OthersSucceed() async {
        // Given: Only Live Pulse fails
        await configureAllSuccess()
        MockLivePulseService.documentsError = TestError.rateLimit

        // When: Loading all data
        let data = await loader.loadAll()

        // Then: All other data should load, Live Pulse data should be empty
        XCTAssertNotNil(data.nextRace)
        XCTAssertNotNil(data.lastResult)
        XCTAssertEqual(data.driverStandings.count, 3)
        XCTAssertEqual(data.constructorStandings.count, 2)
        XCTAssertGreaterThan(data.seasonRaces.count, 0)
        XCTAssertTrue(data.fiaDocuments.isEmpty)
        XCTAssertEqual(data.liveEventName, "")
        XCTAssertEqual(data.liveDocCount, 0)
        XCTAssertEqual(data.recentSessions.count, 1)
        XCTAssertNil(data.errorMessage)
    }

    func testOpenF1Fails_OthersSucceed() async {
        // Given: Only OpenF1 fails
        await configureAllSuccess()
        MockOpenF1Service.sessionsError = TestError.network

        // When: Loading all data
        let data = await loader.loadAll()

        // Then: All other data should load, OpenF1 data should be empty
        XCTAssertNotNil(data.nextRace)
        XCTAssertNotNil(data.lastResult)
        XCTAssertEqual(data.driverStandings.count, 3)
        XCTAssertEqual(data.constructorStandings.count, 2)
        XCTAssertGreaterThan(data.seasonRaces.count, 0)
        XCTAssertEqual(data.fiaDocuments.count, 2)
        XCTAssertTrue(data.recentSessions.isEmpty)
        XCTAssertNil(data.errorMessage)
    }

    // MARK: - All Sources Fail

    func testAllSourcesFail_showsErrorMessage() async {
        // Given: All services throw errors
        MockF1Service.nextRaceError = TestError.network
        MockF1Service.lastResultError = TestError.network
        MockF1Service.driverStandingsError = TestError.decoding
        MockF1Service.constructorStandingsError = TestError.rateLimit
        MockF1Service.currentSeasonError = TestError.network
        MockLivePulseService.documentsError = TestError.rateLimit
        MockOpenF1Service.sessionsError = TestError.network

        // When: Loading all data
        let data = await loader.loadAll()

        // Then: Error message should be set, all data should be nil/empty
        XCTAssertNotNil(data.errorMessage)
        XCTAssertTrue(data.errorMessage!.contains("Couldn't load F1 data"))
        XCTAssertNil(data.nextRace)
        XCTAssertNil(data.lastResult)
        XCTAssertTrue(data.driverStandings.isEmpty)
        XCTAssertTrue(data.constructorStandings.isEmpty)
        XCTAssertTrue(data.seasonRaces.isEmpty)
        XCTAssertTrue(data.fiaDocuments.isEmpty)
        XCTAssertEqual(data.liveEventName, "")
        XCTAssertTrue(data.recentSessions.isEmpty)
    }

    // MARK: - Mixed Partial Failures

    func testPartialF1APIFailures() async {
        // Given: Some f1api.dev calls succeed, some fail
        MockF1Service.nextRaceResult = sampleRace()
        MockF1Service.lastResultError = TestError.network  // This one fails
        MockF1Service.driverStandingsResult = [sampleDriverStanding(position: 1)]
        MockF1Service.constructorStandingsResult = [sampleConstructorStanding(position: 1)]
        MockF1Service.currentSeasonError = TestError.network  // This one fails
        await configureLivePulseSuccess()
        await configureOpenF1Success()

        // When: Loading all data
        let data = await loader.loadAll()

        // Then: Successful calls should return data, failed ones should not
        XCTAssertNotNil(data.nextRace)
        XCTAssertNil(data.lastResult)
        XCTAssertEqual(data.driverStandings.count, 1)
        XCTAssertEqual(data.constructorStandings.count, 1)
        XCTAssertTrue(data.seasonRaces.isEmpty)
        XCTAssertEqual(data.fiaDocuments.count, 2)
        XCTAssertEqual(data.recentSessions.count, 1)
        XCTAssertNil(data.errorMessage)
    }

    // MARK: - OpenF1 Toggle

    func testOpenF1Disabled_SkipsOpenF1Call() async {
        // Given: OpenF1 is disabled
        await configureAllSuccess()
        loader.openF1Enabled = false
        // Even if mock has an error, it shouldn't be called
        MockOpenF1Service.sessionsError = TestError.network

        // When: Loading all data
        let data = await loader.loadAll()

        // Then: OpenF1 data should be empty (no call made), all other data should load
        XCTAssertNotNil(data.nextRace)
        XCTAssertNotNil(data.lastResult)
        XCTAssertEqual(data.driverStandings.count, 3)
        XCTAssertEqual(data.constructorStandings.count, 2)
        XCTAssertGreaterThan(data.seasonRaces.count, 0)
        XCTAssertEqual(data.fiaDocuments.count, 2)
        XCTAssertTrue(data.recentSessions.isEmpty) // Skipped because disabled
        XCTAssertNil(data.errorMessage)
    }

    func testOpenF1Enabled_CallsAndSucceeds() async {
        // Given: OpenF1 is enabled
        await configureAllSuccess()
        loader.openF1Enabled = true

        // When: Loading all data
        let data = await loader.loadAll()

        // Then: OpenF1 data should be present
        XCTAssertEqual(data.recentSessions.count, 1)
    }

    // MARK: - Edge Cases

    func testEmptyLivePulseDocuments() async {
        // Given: Live Pulse returns empty documents but no error
        await configureAllSuccess()
        MockLivePulseService.documentsResult = FIADocumentsResponse(
            documents: [],
            event: "Test Event",
            meeting_index: 1
        )

        // When: Loading all data
        let data = await loader.loadAll()

        // Then: Event name should still be present, doc count should be 0
        XCTAssertEqual(data.liveEventName, "Test Event")
        XCTAssertEqual(data.liveDocCount, 0)
        XCTAssertTrue(data.fiaDocuments.isEmpty)
        XCTAssertNil(data.errorMessage)
    }

    func testOptionalRaceReturnsNil() async {
        // Given: fetchNextRace returns nil (no upcoming race)
        await configureAllSuccess()
        MockF1Service.nextRaceResult = nil

        // When: Loading all data
        let data = await loader.loadAll()

        // Then: nextRace should be nil, but no error
        XCTAssertNil(data.nextRace)
        XCTAssertNotNil(data.lastResult)
        XCTAssertNil(data.errorMessage)
    }

    // MARK: - Helpers

    /// Configures all mock services to return sample valid data.
    private func configureAllSuccess() async {
        MockF1Service.nextRaceResult = sampleRace()
        MockF1Service.lastResultResult = sampleRaceResult()
        MockF1Service.driverStandingsResult = [
            sampleDriverStanding(position: 1),
            sampleDriverStanding(position: 2),
            sampleDriverStanding(position: 3),
        ]
        MockF1Service.constructorStandingsResult = [
            sampleConstructorStanding(position: 1),
            sampleConstructorStanding(position: 2),
        ]
        // Create races with var to work around let properties
        var races: [F1Race] = []
        for round in 1...24 {
            races.append(sampleRace(round: round))
        }
        MockF1Service.currentSeasonResult = races
        await configureLivePulseSuccess()
        await configureOpenF1Success()
    }

    private func configureLivePulseSuccess() async {
        MockLivePulseService.documentsResult = FIADocumentsResponse(
            documents: [
                sampleDocument(title: "Race Classification", category: "Results"),
                sampleDocument(title: "Stewards Decision", category: "Decision"),
            ],
            event: "Monaco Grand Prix",
            meeting_index: 1
        )
    }

    private func configureOpenF1Success() async {
        MockOpenF1Service.sessionsResult = [
            F1OpenF1Session(
                session_key: 101,
                session_name: "Race",
                session_type: "Race",
                country_name: "Monaco",
                circuit_short_name: "Monte Carlo",
                date_start: "2026-05-24T14:00:00Z",
                date_end: nil,
                year: 2026
            )
        ]
    }

    // MARK: - Sample Data Factories

    private func sampleRace(round: Int = 7) -> F1Race {
        F1Race(
            raceId: 100 + round,
            round: round,
            raceName: "Grand Prix \(round)",
            date: "2026-05-24",
            time: "14:00:00Z",
            circuit: F1Circuit(
                circuitId: "circuit_\(round)",
                circuitName: "Circuit \(round)",
                country: "Country",
                city: "City",
                circuitLength: "3.3",
                lapRecord: nil,
                corners: nil,
                firstParticipationYear: nil,
                url: nil
            ),
            url: nil,
            laps: 78,
            winner: nil,
            fp1: nil,
            fp2: nil,
            fp3: nil,
            qualy: nil,
            sprintQualy: nil,
            sprintRace: nil
        )
    }

    private func sampleRaceResult() -> F1RaceResult {
        F1RaceResult(
            raceId: 100,
            round: 6,
            raceName: "Emilia Romagna Grand Prix",
            date: "2026-05-17",
            time: "14:00:00Z",
            circuit: nil,
            results: [
                F1RaceResultEntry(
                    position: 1,
                    driver: F1ResultDriver(
                        driverId: "max_verstappen",
                        name: "Max",
                        surname: "Verstappen",
                        shortName: "VER",
                        number: "1",
                        nationality: "Dutch"
                    ),
                    team: F1ResultTeam(teamId: "red_bull", teamName: "Red Bull Racing", nationality: "Austrian"),
                    points: 25,
                    grid: 1,
                    time: "1:32:45.678",
                    retired: false,
                    fastLap: "1:18.456"
                )
            ]
        )
    }

    private func sampleDriverStanding(position: Int) -> F1DriverStanding {
        let names = [
            (1, "Max", "Verstappen", "VER", "red_bull"),
            (2, "Lewis", "Hamilton", "HAM", "mercedes"),
            (3, "Charles", "Leclerc", "LEC", "ferrari"),
        ]
        let entry = names[position - 1]
        return F1DriverStanding(
            position: position,
            driverId: entry.4,
            name: entry.1,
            surname: entry.2,
            shortName: entry.3,
            number: "\(position == 1 ? "1" : "\(position + 10)")",
            nationality: "Unknown",
            teamId: entry.4,
            points: 100 - (position - 1) * 10,
            wins: max(0, 4 - (position - 1))
        )
    }

    private func sampleConstructorStanding(position: Int) -> F1ConstructorStanding {
        let teamNames = ["Red Bull Racing", "Mercedes"]
        let countries = ["Austrian", "German"]
        let idx = position - 1
        let name = teamNames[idx]
        let teamId = name.lowercased().replacingOccurrences(of: " ", with: "_")
        return F1ConstructorStanding(
            classificationId: position,
            teamId: teamId,
            points: 200 - idx * 50,
            position: position,
            wins: max(0, 6 - idx * 3),
            team: F1TeamStandingInfo(
                teamName: name,
                country: countries[idx],
                firstAppareance: 2005,
                constructorsChampionships: position == 1 ? 6 : 8,
                driversChampionships: position == 1 ? 4 : 9,
                url: nil
            )
        )
    }

    private func sampleDocument(title: String, category: String) -> FIADocument {
        FIADocument(
            analysis: FIADocumentAnalysis(
                _version: 1,
                details: nil,
                document_category: category,
                drivers_involved: nil,
                priority: "low",
                short_summary: "Test document"
            ),
            date: "2026-05-24T14:30:00.000Z",
            title: title,
            url: "https://example.com/doc/\(title)"
        )
    }
}
