import XCTest
import SwiftUI
@testable import WorldCupApp

// MARK: - Snapshot Tests for F1 Tab Sub-Views

@MainActor
final class F1TabSnapshotTests: XCTestCase {

    // MARK: - F1OverviewTab

    func testOverviewTab_emptyState_renders() {
        let view = F1OverviewTab(
            nextRace: nil,
            lastResult: nil,
            driverStandings: [],
            constructorStandings: [],
            seasonRaces: [],
            fiaDocuments: [],
            liveDocCount: 0,
            refreshAction: {}
        )
        XCTAssertNoThrow(view, "Overview tab should render in empty state")
        let image = renderView(view, size: CGSize(width: 390, height: 844))
        XCTAssertNotNil(image, "Overview tab (empty) should render without crashing")
        attachSnapshot(image, name: "F1OverviewTab_Empty")
    }

    func testOverviewTab_fullData_renders() {
        let view = F1OverviewTab(
            nextRace: sampleRace(round: 7),
            lastResult: sampleRaceResult(),
            driverStandings: [
                sampleDriverStanding(position: 1),
                sampleDriverStanding(position: 2),
                sampleDriverStanding(position: 3),
            ],
            constructorStandings: [
                sampleConstructorStanding(position: 1),
                sampleConstructorStanding(position: 2),
            ],
            seasonRaces: (1...12).map { sampleRace(round: $0) },
            fiaDocuments: [
                sampleDocument(title: "Race Classification", category: "Results", priority: "low"),
                sampleDocument(title: "Stewards Decision", category: "Decision", priority: "high"),
                sampleDocument(title: "Technical Delegate", category: "scrutineering", priority: "medium"),
            ],
            liveDocCount: 3,
            refreshAction: {}
        )
        XCTAssertNoThrow(view, "Overview tab should render with full data")
        let image = renderView(view, size: CGSize(width: 390, height: 1200))
        XCTAssertNotNil(image, "Overview tab (full data) should render without crashing")
        attachSnapshot(image, name: "F1OverviewTab_FullData")
    }

    func testOverviewTab_partialData_renders() {
        // Only last result and documents — no next race, no standings
        let view = F1OverviewTab(
            nextRace: nil,
            lastResult: sampleRaceResult(),
            driverStandings: [],
            constructorStandings: [],
            seasonRaces: [],
            fiaDocuments: [sampleDocument(title: "Qualifying Classification", category: "Results", priority: "low")],
            liveDocCount: 1,
            refreshAction: {}
        )
        XCTAssertNoThrow(view, "Overview tab should render with partial data")
        let image = renderView(view, size: CGSize(width: 390, height: 1000))
        XCTAssertNotNil(image, "Overview tab (partial) should render without crashing")
        attachSnapshot(image, name: "F1OverviewTab_PartialData")
    }

    // MARK: - F1StandingsTab

    func testStandingsTab_empty_renders() {
        let view = F1StandingsTab(
            driverStandings: [],
            constructorStandings: [],
            refreshAction: {}
        )
        XCTAssertNoThrow(view, "Standings tab should render empty")
        let image = renderView(view, size: CGSize(width: 390, height: 400))
        XCTAssertNotNil(image, "Standings tab (empty) should render without crashing")
        attachSnapshot(image, name: "F1StandingsTab_Empty")
    }

    func testStandingsTab_withDrivers_renders() {
        let drivers = (1...5).map { sampleDriverStanding(position: $0) }
        let view = F1StandingsTab(
            driverStandings: drivers,
            constructorStandings: [],
            refreshAction: {}
        )
        XCTAssertNoThrow(view, "Standings tab should render with drivers")
        let image = renderView(view, size: CGSize(width: 390, height: 700))
        XCTAssertNotNil(image, "Standings tab (drivers) should render without crashing")
        attachSnapshot(image, name: "F1StandingsTab_WithDrivers")
    }

    func testStandingsTab_withBoth_renders() {
        let drivers = (1...5).map { sampleDriverStanding(position: $0) }
        let constructors = (1...3).map { sampleConstructorStanding(position: $0) }
        let view = F1StandingsTab(
            driverStandings: drivers,
            constructorStandings: constructors,
            refreshAction: {}
        )
        XCTAssertNoThrow(view, "Standings tab should render with both standings")
        let image = renderView(view, size: CGSize(width: 390, height: 900))
        XCTAssertNotNil(image, "Standings tab (both) should render without crashing")
        attachSnapshot(image, name: "F1StandingsTab_WithBoth")
    }

    // MARK: - F1LiveTab

    func testLiveTab_empty_renders() {
        let view = F1LiveTab(
            documents: [],
            docCount: 0,
            refreshAction: {}
        )
        XCTAssertNoThrow(view, "Live tab should render empty")
        let image = renderView(view, size: CGSize(width: 390, height: 700))
        XCTAssertNotNil(image, "Live tab (empty) should render without crashing")
        attachSnapshot(image, name: "F1LiveTab_Empty")
    }

    func testLiveTab_withDocuments_renders() {
        let docs = [
            sampleDocument(title: "Race Classification", category: "Results", priority: "low"),
            sampleDocument(title: "Stewards Decision", category: "Decision", priority: "high"),
            sampleDocument(title: "Summons", category: "Summons", priority: "medium"),
            sampleDocument(title: "Technical Report", category: "scrutineering", priority: "low"),
            sampleDocument(title: "Event Info", category: "event_info", priority: "low"),
            sampleDocument(title: "Parc Ferme", category: "parc_ferme_changes", priority: "medium"),
        ]
        let view = F1LiveTab(
            documents: docs,
            docCount: 6,
            refreshAction: {}
        )
        XCTAssertNoThrow(view, "Live tab should render with documents")
        let image = renderView(view, size: CGSize(width: 390, height: 1200))
        XCTAssertNotNil(image, "Live tab (documents) should render without crashing")
        attachSnapshot(image, name: "F1LiveTab_WithDocuments")
    }

    func testLiveTab_withPenalties_renders() {
        // Two high-priority penalty docs should trigger the steward actions banner
        let docs = [
            sampleDocument(title: "Race Classification", category: "Results", priority: "low"),
            sampleDocument(title: "Penalty for Driver X", category: "Decision", priority: "high"),
            sampleDocument(title: "Infringement Notice", category: "infringement", priority: "high"),
            sampleDocument(title: "Minor Infringement", category: "infringement", priority: "low"),
        ]
        let view = F1LiveTab(
            documents: docs,
            docCount: 4,
            refreshAction: {}
        )
        XCTAssertNoThrow(view, "Live tab should render with penalties")
        let image = renderView(view, size: CGSize(width: 390, height: 1100))
        XCTAssertNotNil(image, "Live tab (penalties) should render without crashing")
        attachSnapshot(image, name: "F1LiveTab_WithPenalties")
    }

    // MARK: - F1LiveStatusBar

    func testLiveStatusBar_withEvent_renders() {
        let view = F1LiveStatusBar(eventName: "Singapore Grand Prix", docCount: 5)
        XCTAssertNoThrow(view, "Status bar should render with event")
        let image = renderView(view, size: CGSize(width: 390, height: 44))
        XCTAssertNotNil(image, "Status bar (with event) should render")
        attachSnapshot(image, name: "F1LiveStatusBar_WithEvent")
    }

    func testLiveStatusBar_noEvent_renders() {
        let view = F1LiveStatusBar(eventName: "", docCount: 0)
        XCTAssertNoThrow(view, "Status bar should render without event")
        let image = renderView(view, size: CGSize(width: 390, height: 44))
        XCTAssertNotNil(image, "Status bar (no event) should render")
        attachSnapshot(image, name: "F1LiveStatusBar_NoEvent")
    }

    // MARK: - F1TabPicker

    func testTabPicker_rendersAllSections() {
        // Verify all three sections are present
        let sections = DashboardSection.allCases
        XCTAssertEqual(sections.count, 3, "Should have exactly 3 sections")
        XCTAssertEqual(sections[0].rawValue, "Race Hub")
        XCTAssertEqual(sections[1].rawValue, "Standings")
        XCTAssertEqual(sections[2].rawValue, "Live")
    }

    func testTabPicker_viewRenders() {
        let view = F1TabPicker(selection: .constant(.overview))
        XCTAssertNoThrow(view, "Tab picker should render")
        let image = renderView(view, size: CGSize(width: 390, height: 50))
        XCTAssertNotNil(image, "Tab picker should render without crashing")
        attachSnapshot(image, name: "F1TabPicker_OverviewSelected")
    }

    func testTabPicker_liveSelected_viewRenders() {
        let view = F1TabPicker(selection: .constant(.live))
        XCTAssertNoThrow(view, "Tab picker (live selected) should render")
        let image = renderView(view, size: CGSize(width: 390, height: 50))
        XCTAssertNotNil(image, "Tab picker (live) should render without crashing")
        attachSnapshot(image, name: "F1TabPicker_LiveSelected")
    }

    // MARK: - Rendering Helpers

    /// Renders a SwiftUI view into a UIImage at the given size.
    private func renderView<V: View>(_ view: V, size: CGSize) -> UIImage? {
        let controller = UIHostingController(rootView: view)
        controller.view.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.12, alpha: 1)

        let window = UIWindow(frame: CGRect(origin: .zero, size: size))
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            window.windowScene = scene
        }
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.view.frame = window.bounds
        controller.view.layoutIfNeeded()

        // Render to image (1x scale to keep attachments lean)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { ctx in
            controller.view.layer.render(in: ctx.cgContext)
        }
    }

    /// Attaches a snapshot image to the test for visual inspection in the test report.
    private func attachSnapshot(_ image: UIImage?, name: String) {
        guard let image else { return }
        let attachment = XCTAttachment(image: image)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
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
            fp1: F1Session(date: "2026-05-22", time: "12:30:00Z"),
            fp2: F1Session(date: "2026-05-22", time: "16:00:00Z"),
            fp3: F1Session(date: "2026-05-23", time: "11:00:00Z"),
            qualy: F1Session(date: "2026-05-23", time: "14:00:00Z"),
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
                ),
                F1RaceResultEntry(
                    position: 2,
                    driver: F1ResultDriver(
                        driverId: "lewis_hamilton",
                        name: "Lewis",
                        surname: "Hamilton",
                        shortName: "HAM",
                        number: "44",
                        nationality: "British"
                    ),
                    team: F1ResultTeam(teamId: "mercedes", teamName: "Mercedes", nationality: "German"),
                    points: 18,
                    grid: 3,
                    time: "1:33:02.123",
                    retired: false,
                    fastLap: "1:19.234"
                ),
                F1RaceResultEntry(
                    position: 3,
                    driver: F1ResultDriver(
                        driverId: "charles_leclerc",
                        name: "Charles",
                        surname: "Leclerc",
                        shortName: "LEC",
                        number: "16",
                        nationality: "Monegasque"
                    ),
                    team: F1ResultTeam(teamId: "ferrari", teamName: "Ferrari", nationality: "Italian"),
                    points: 15,
                    grid: 2,
                    time: "1:33:15.456",
                    retired: false,
                    fastLap: nil
                ),
            ]
        )
    }

    private func sampleDriverStanding(position: Int) -> F1DriverStanding {
        let entries = [
            (1, "Max", "Verstappen", "VER", "red_bull"),
            (2, "Lewis", "Hamilton", "HAM", "mercedes"),
            (3, "Charles", "Leclerc", "LEC", "ferrari"),
            (4, "Lando", "Norris", "NOR", "mclaren"),
            (5, "Carlos", "Sainz", "SAI", "ferrari"),
        ]
        let entry = entries[min(position - 1, entries.count - 1)]
        return F1DriverStanding(
            position: position,
            driverId: entry.4,
            name: entry.1,
            surname: entry.2,
            shortName: entry.3,
            number: "\(position)",
            nationality: "Unknown",
            teamId: entry.4,
            points: 120 - (position - 1) * 15,
            wins: max(0, 5 - (position - 1))
        )
    }

    private func sampleConstructorStanding(position: Int) -> F1ConstructorStanding {
        let teamNames = ["Red Bull Racing", "Mercedes", "Ferrari"]
        let countries = ["Austrian", "German", "Italian"]
        let idx = min(position - 1, teamNames.count - 1)
        let name = teamNames[idx]
        let teamId = name.lowercased().replacingOccurrences(of: " ", with: "_")
        return F1ConstructorStanding(
            classificationId: position,
            teamId: teamId,
            points: 250 - idx * 60,
            position: position,
            wins: max(0, 7 - idx * 2),
            team: F1TeamStandingInfo(
                teamName: name,
                country: countries[idx],
                firstAppareance: idx == 0 ? 2005 : (idx == 1 ? 1970 : 1950),
                constructorsChampionships: idx == 0 ? 6 : (idx == 1 ? 8 : 16),
                driversChampionships: idx == 0 ? 4 : (idx == 1 ? 7 : 15),
                url: nil
            )
        )
    }

    /// Creates a sample document. Only penalty-type documents get `details` with penalty info.
    private func sampleDocument(title: String, category: String, priority: String) -> FIADocument {
        let isPenalty = category.lowercased() == "decision" ||
                        category.lowercased() == "infringement" ||
                        category.lowercased() == "summons"
        let details: FIADocumentDetails? = isPenalty ? FIADocumentDetails(
            reasoning: "Driver exceeded track limits",
            decision_type: "Time Penalty",
            type: nil,
            duration_in_seconds: priority == "high" ? 10 : nil,
            fine_amount: nil,
            grid_position_change: nil,
            points: priority == "medium" ? 2 : nil,
            total_points_in_last_12_months: nil
        ) : nil

        return FIADocument(
            analysis: FIADocumentAnalysis(
                _version: 1,
                details: details,
                document_category: category,
                drivers_involved: isPenalty && priority == "high" ? ["16", "1"] : nil,
                priority: priority,
                short_summary: "\(priority.capitalized) priority document: \(title)"
            ),
            date: "2026-05-24T14:30:00.000Z",
            title: title,
            url: "https://example.com/doc/\(title.replacingOccurrences(of: " ", with: "_"))"
        )
    }
}
