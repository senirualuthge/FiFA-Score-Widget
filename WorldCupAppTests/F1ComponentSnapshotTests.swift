import XCTest
import SwiftUI
@testable import WorldCupApp

// MARK: - Snapshot Tests for Individual Sub-Components

@MainActor
final class F1ComponentSnapshotTests: XCTestCase {

    // MARK: - QuickStatCard

    func testQuickStatCard_drivers_renders() {
        let view = QuickStatCard(title: "Drivers", value: "20", subtitle: "VER leads", icon: "person.3.fill", color: .yellow)
        assertSnapshot(view, size: CGSize(width: 120, height: 90), name: "QuickStatCard_Drivers")
    }

    func testQuickStatCard_constructors_renders() {
        let view = QuickStatCard(title: "Constructors", value: "10", subtitle: "Red Bull Racing", icon: "building.2.fill", color: .blue)
        assertSnapshot(view, size: CGSize(width: 120, height: 90), name: "QuickStatCard_Constructors")
    }

    func testQuickStatCard_races_renders() {
        let view = QuickStatCard(title: "Races", value: "24", subtitle: "2026 season", icon: "flag.checkered", color: .green)
        assertSnapshot(view, size: CGSize(width: 120, height: 90), name: "QuickStatCard_Races")
    }

    // MARK: - LiveFeedMiniCard

    func testLiveFeedMiniCard_results_renders() {
        let view = LiveFeedMiniCard(document: sampleDoc(title: "Race Classification", category: "Results", priority: "low"))
        assertSnapshot(view, size: CGSize(width: 370, height: 60), name: "LiveFeedMiniCard_Results")
    }

    func testLiveFeedMiniCard_penaltyHigh_renders() {
        let view = LiveFeedMiniCard(document: sampleDoc(title: "Stewards Decision", category: "Decision", priority: "high"))
        assertSnapshot(view, size: CGSize(width: 370, height: 60), name: "LiveFeedMiniCard_PenaltyHigh")
    }

    func testLiveFeedMiniCard_mediumPriority_renders() {
        let view = LiveFeedMiniCard(document: sampleDoc(title: "Technical Report", category: "scrutineering", priority: "medium"))
        assertSnapshot(view, size: CGSize(width: 370, height: 60), name: "LiveFeedMiniCard_Medium")
    }

    // MARK: - DashboardPodiumView

    func testDashboardPodiumView_withData_renders() {
        let drivers = (1...3).map { F1ComponentSnapshotTests.sampleDriver(position: $0) }
        let view = DashboardPodiumView(drivers: drivers)
        assertSnapshot(view, size: CGSize(width: 350, height: 70), name: "DashboardPodiumView_WithData")
    }

    func testDashboardPodiumView_empty_renders() {
        let view = DashboardPodiumView(drivers: [])
        assertSnapshot(view, size: CGSize(width: 350, height: 70), name: "DashboardPodiumView_Empty")
    }

    // MARK: - DriverStandingsList

    func testDriverStandingsList_full_renders() {
        let drivers = (1...8).map { F1ComponentSnapshotTests.sampleDriver(position: $0) }
        let view = DriverStandingsList(standings: drivers)
        assertSnapshot(view, size: CGSize(width: 350, height: 280), name: "DriverStandingsList_Full")
    }

    func testDriverStandingsList_empty_renders() {
        let view = DriverStandingsList(standings: [])
        assertSnapshot(view, size: CGSize(width: 350, height: 50), name: "DriverStandingsList_Empty")
    }

    // MARK: - ConstructorStandingsList

    func testConstructorStandingsList_full_renders() {
        let constructors = F1ComponentSnapshotTests.sampleConstructors()
        let view = ConstructorStandingsList(standings: constructors)
        assertSnapshot(view, size: CGSize(width: 350, height: 160), name: "ConstructorStandingsList_Full")
    }

    func testConstructorStandingsList_empty_renders() {
        let view = ConstructorStandingsList(standings: [])
        assertSnapshot(view, size: CGSize(width: 350, height: 50), name: "ConstructorStandingsList_Empty")
    }

    // MARK: - NavPill

    func testNavPill_yellow_renders() {
        let view = NavPill(title: "Standings", icon: "trophy.fill", color: .yellow) { EmptyView() }
        assertSnapshot(view, size: CGSize(width: 120, height: 36), name: "NavPill_Yellow")
    }

    func testNavPill_red_renders() {
        let view = NavPill(title: "Drivers", icon: "person.3.fill", color: .red) { EmptyView() }
        assertSnapshot(view, size: CGSize(width: 120, height: 36), name: "NavPill_Red")
    }

    func testNavPill_blue_renders() {
        let view = NavPill(title: "Teams", icon: "building.2.fill", color: .blue) { EmptyView() }
        assertSnapshot(view, size: CGSize(width: 120, height: 36), name: "NavPill_Blue")
    }

    // MARK: - MiniNavCard

    func testMiniNavCard_red_renders() {
        let view = MiniNavCard(title: "Live Feed", icon: "antenna.radiowaves.left.and.right", color: .red) { EmptyView() }
        assertSnapshot(view, size: CGSize(width: 110, height: 70), name: "MiniNavCard_Red")
    }

    func testMiniNavCard_green_renders() {
        let view = MiniNavCard(title: "Calendar", icon: "calendar", color: .green) { EmptyView() }
        assertSnapshot(view, size: CGSize(width: 110, height: 70), name: "MiniNavCard_Green")
    }

    // MARK: - NavPillSmall

    func testNavPillSmall_pink_renders() {
        let view = NavPillSmall(title: "Session Detail", icon: "flag.checkered", color: .pink) { EmptyView() }
        assertSnapshot(view, size: CGSize(width: 180, height: 40), name: "NavPillSmall_Pink")
    }

    func testNavPillSmall_yellow_renders() {
        let view = NavPillSmall(title: "Standings", icon: "trophy.fill", color: .yellow) { EmptyView() }
        assertSnapshot(view, size: CGSize(width: 180, height: 40), name: "NavPillSmall_Yellow")
    }

    // MARK: - NextRaceCard

    func testNextRaceCard_collapsed_renders() {
        let view = NextRaceCard(race: F1ComponentSnapshotTests.sampleRace())
        assertSnapshot(view, size: CGSize(width: 370, height: 200), name: "NextRaceCard_Collapsed")
    }

    func testNextRaceCard_noCircuit_renders() {
        let race = F1Race(
            raceId: 1, round: 7,
            raceName: "British Grand Prix",
            date: "2026-07-19", time: "14:00:00Z",
            circuit: nil, url: nil, laps: nil,
            winner: nil, fp1: nil, fp2: nil, fp3: nil,
            qualy: nil, sprintQualy: nil, sprintRace: nil
        )
        let view = NextRaceCard(race: race)
        assertSnapshot(view, size: CGSize(width: 370, height: 160), name: "NextRaceCard_NoCircuit")
    }

    // MARK: - SessionRow

    func testSessionRow_race_renders() {
        let view = SessionRow(label: "\u{1F3C1} Race", session: F1Session(date: "2026-07-19", time: "14:00:00Z"), isRace: true)
        assertSnapshot(view, size: CGSize(width: 350, height: 30), name: "SessionRow_Race")
    }

    func testSessionRow_practice_renders() {
        let view = SessionRow(label: "Free Practice 1", session: F1Session(date: "2026-07-17", time: "12:30:00Z"), isRace: false)
        assertSnapshot(view, size: CGSize(width: 350, height: 24), name: "SessionRow_Practice")
    }

    func testSessionRow_noTime_renders() {
        let view = SessionRow(label: "Qualifying", session: F1Session(date: "2026-07-18", time: nil), isRace: false)
        assertSnapshot(view, size: CGSize(width: 350, height: 24), name: "SessionRow_NoTime")
    }

    // MARK: - LastRaceCard

    func testLastRaceCard_withResults_renders() {
        let result = F1RaceResult(
            raceId: 1, round: 6,
            raceName: "Austrian Grand Prix",
            date: "2026-07-05", time: "14:00:00Z",
            circuit: nil,
            results: [
                F1RaceResultEntry(position: 1, driver: F1ResultDriver(driverId: "verstappen", name: "Max", surname: "Verstappen", shortName: "VER", number: "1", nationality: "Dutch"), team: F1ResultTeam(teamId: "red_bull", teamName: "Red Bull Racing", nationality: "Austrian"), points: 25, grid: 1, time: "1:28:45", retired: false, fastLap: "1:07.2"),
                F1RaceResultEntry(position: 2, driver: F1ResultDriver(driverId: "norris", name: "Lando", surname: "Norris", shortName: "NOR", number: "4", nationality: "British"), team: F1ResultTeam(teamId: "mclaren", teamName: "McLaren", nationality: "British"), points: 18, grid: 3, time: "1:29:02", retired: false, fastLap: nil),
                F1RaceResultEntry(position: 3, driver: F1ResultDriver(driverId: "hamilton", name: "Lewis", surname: "Hamilton", shortName: "HAM", number: "44", nationality: "British"), team: F1ResultTeam(teamId: "mercedes", teamName: "Mercedes", nationality: "German"), points: 15, grid: 5, time: "1:29:15", retired: false, fastLap: nil),
            ]
        )
        let view = LastRaceCard(result: result)
        assertSnapshot(view, size: CGSize(width: 370, height: 200), name: "LastRaceCard_WithResults")
    }

    func testLastRaceCard_noResults_renders() {
        let result = F1RaceResult(raceId: 1, round: 6, raceName: "Austrian Grand Prix", date: nil, time: nil, circuit: nil, results: nil)
        let view = LastRaceCard(result: result)
        assertSnapshot(view, size: CGSize(width: 370, height: 70), name: "LastRaceCard_NoResults")
    }

    // MARK: - F1TabPicker

    func testTabPicker_overview_renders() {
        let view = F1TabPicker(selection: .constant(.overview))
        assertSnapshot(view, size: CGSize(width: 370, height: 44), name: "F1TabPicker_Overview")
    }

    func testTabPicker_live_renders() {
        let view = F1TabPicker(selection: .constant(.live))
        assertSnapshot(view, size: CGSize(width: 370, height: 44), name: "F1TabPicker_Live")
    }

    // MARK: - F1LiveStatusBar

    func testLiveStatusBar_withEvent_renders() {
        let view = F1LiveStatusBar(eventName: "Singapore Grand Prix", docCount: 5)
        assertSnapshot(view, size: CGSize(width: 370, height: 40), name: "F1LiveStatusBar_WithEvent")
    }

    func testLiveStatusBar_noEvent_renders() {
        let view = F1LiveStatusBar(eventName: "", docCount: 0)
        assertSnapshot(view, size: CGSize(width: 370, height: 40), name: "F1LiveStatusBar_NoEvent")
    }

    // MARK: - Helpers

    private func assertSnapshot<V: View>(_ view: V, size: CGSize, name: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertNoThrow(view, "\(name) should construct without crashing", file: file, line: line)
        let image = renderView(view, size: size)
        XCTAssertNotNil(image, "\(name) should render without crashing", file: file, line: line)
        attachSnapshot(image, name: name)
    }

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

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { ctx in
            controller.view.layer.render(in: ctx.cgContext)
        }
    }

    private func attachSnapshot(_ image: UIImage?, name: String) {
        guard let image else { return }
        let attachment = XCTAttachment(image: image)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    // MARK: - Sample Data

    private func sampleDoc(title: String, category: String, priority: String) -> FIADocument {
        let isPenalty = ["decision", "infringement", "summons"].contains(category.lowercased())
        return FIADocument(
            analysis: FIADocumentAnalysis(
                _version: 1,
                details: isPenalty ? FIADocumentDetails(reasoning: "Test", decision_type: "Time Penalty", type: nil, duration_in_seconds: priority == "high" ? 10 : nil, fine_amount: nil, grid_position_change: nil, points: priority == "medium" ? 2 : nil, total_points_in_last_12_months: nil) : nil,
                document_category: category,
                drivers_involved: isPenalty && priority == "high" ? ["16", "1"] : nil,
                priority: priority,
                short_summary: "\(priority.capitalized) priority document: \(title)"
            ),
            date: "2026-07-11T\(priority == "high" ? "14:30:00" : "15:00:00").000Z",
            title: title,
            url: nil
        )
    }

    static private func sampleDriver(position: Int) -> F1DriverStanding {
        let entries = [
            (1, "Max", "Verstappen", "VER", "red_bull"),
            (2, "Lewis", "Hamilton", "HAM", "mercedes"),
            (3, "Charles", "Leclerc", "LEC", "ferrari"),
            (4, "Lando", "Norris", "NOR", "mclaren"),
            (5, "Carlos", "Sainz", "SAI", "ferrari"),
            (6, "George", "Russell", "RUS", "mercedes"),
            (7, "Oscar", "Piastri", "PIA", "mclaren"),
            (8, "Fernando", "Alonso", "ALO", "aston_martin"),
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

    static private func sampleConstructors() -> [F1ConstructorStanding] {
        [
            F1ConstructorStanding(classificationId: 1, teamId: "red_bull", points: 250, position: 1, wins: 7, team: F1TeamStandingInfo(teamName: "Red Bull Racing", country: "Austrian", firstAppareance: 2005, constructorsChampionships: 6, driversChampionships: 4, url: nil)),
            F1ConstructorStanding(classificationId: 2, teamId: "mercedes", points: 190, position: 2, wins: 5, team: F1TeamStandingInfo(teamName: "Mercedes", country: "German", firstAppareance: 1970, constructorsChampionships: 8, driversChampionships: 7, url: nil)),
            F1ConstructorStanding(classificationId: 3, teamId: "ferrari", points: 160, position: 3, wins: 3, team: F1TeamStandingInfo(teamName: "Ferrari", country: "Italian", firstAppareance: 1950, constructorsChampionships: 16, driversChampionships: 15, url: nil)),
            F1ConstructorStanding(classificationId: 4, teamId: "mclaren", points: 110, position: 4, wins: 1, team: F1TeamStandingInfo(teamName: "McLaren", country: "British", firstAppareance: 1966, constructorsChampionships: 8, driversChampionships: 12, url: nil)),
        ]
    }

    static private func sampleRace() -> F1Race {
        F1Race(
            raceId: 1, round: 7,
            raceName: "British Grand Prix",
            date: "2026-07-19", time: "14:00:00Z",
            circuit: F1Circuit(circuitId: "silverstone", circuitName: "Silverstone Circuit", country: "United Kingdom", city: "Silverstone", circuitLength: "5.891", lapRecord: "1:27.097", corners: 18, firstParticipationYear: 1950, url: nil),
            url: nil, laps: 52, winner: nil,
            fp1: F1Session(date: "2026-07-17", time: "12:30:00Z"),
            fp2: F1Session(date: "2026-07-17", time: "16:00:00Z"),
            fp3: F1Session(date: "2026-07-18", time: "11:00:00Z"),
            qualy: F1Session(date: "2026-07-18", time: "14:00:00Z"),
            sprintQualy: nil, sprintRace: nil
        )
    }
}
