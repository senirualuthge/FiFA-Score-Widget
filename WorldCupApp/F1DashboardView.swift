import SwiftUI

struct F1DashboardView: View {
    // MARK: - Settings
    @StateObject private var settings = F1Settings()
    @State private var showSettings = false

    // MARK: - Data from all sources
    @State private var selectedSection: DashboardSection = .overview

    // f1api.dev data
    @State private var nextRace: F1Race?
    @State private var lastResult: F1RaceResult?
    @State private var driverStandings: [F1DriverStanding] = []
    @State private var constructorStandings: [F1ConstructorStanding] = []
    @State private var seasonRaces: [F1Race] = []

    // F1 Live Pulse data
    @State private var fiaDocuments: [FIADocument] = []
    @State private var liveEventName: String = ""
    @State private var liveDocCount: Int = 0

    // OpenF1 data
    @State private var recentSessions: [F1OpenF1Session] = []

    // UI state
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                F1Wallpaper()

                Group {
                    if isLoading {
                        ProgressView("Loading F1 data…")
                            .tint(.white)
                            .foregroundStyle(.white)
                    } else if errorMessage != nil {
                        errorState
                    } else {
                        dashboardContent
                    }
                }
            }
            .navigationTitle("Formula 1")
            .toolbar { toolbarContent }
            .task { await loadAll() }
            .preferredColorScheme(settings.preferredColorScheme)
            .onChange(of: selectedSection) { _, newValue in
                settings.defaultTab = newValue.rawValue
            }
            .sheet(isPresented: $showSettings) {
                F1SettingsView(settings: settings)
            }
        }
    }

    // MARK: - Error State

    private var errorState: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
            Text(errorMessage!)
                .multilineTextAlignment(.center)
            Button("Retry") { Task { await loadAll() } }
                .buttonStyle(.borderedProminent)
        }
        .foregroundStyle(.white.opacity(0.8))
        .padding()
    }

    // MARK: - Dashboard Content

    private var dashboardContent: some View {
        VStack(spacing: 0) {
            if settings.showLiveStatusBar {
                F1LiveStatusBar(eventName: liveEventName, docCount: liveDocCount)
            }

            F1TabPicker(selection: $selectedSection)

            TabView(selection: $selectedSection) {
                F1OverviewTab(
                    nextRace: nextRace,
                    lastResult: lastResult,
                    driverStandings: driverStandings,
                    constructorStandings: constructorStandings,
                    seasonRaces: seasonRaces,
                    fiaDocuments: fiaDocuments,
                    liveDocCount: liveDocCount,
                    refreshAction: loadAll
                )
                .tag(DashboardSection.overview)

                F1StandingsTab(
                    driverStandings: driverStandings,
                    constructorStandings: constructorStandings,
                    refreshAction: loadAll
                )
                .tag(DashboardSection.standings)

                F1LiveTab(
                    documents: fiaDocuments,
                    docCount: liveDocCount,
                    refreshAction: loadAll
                )
                .tag(DashboardSection.live)
            }
            #if os(iOS)
            .tabViewStyle(.page(indexDisplayMode: .never))
            #endif
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        #if os(iOS)
        ToolbarItem(placement: .navigationBarTrailing) {
            Menu {
                NavigationLink("🔴 Live Feed") { F1LiveFeedView() }
                NavigationLink("🏁 Session Detail") { F1SessionDetailView() }
                NavigationLink("📊 Telemetry") { F1TelemetryView() }
                NavigationLink("📊 Compare") { F1ComparisonView() }
                NavigationLink("🏆 Standings") { F1StandingsView() }
                NavigationLink("🏎️ Drivers") { F1DriverListView() }
                NavigationLink("🏢 Teams") { F1TeamListView() }
                NavigationLink("📅 Calendar") { F1RaceCalendarView() }
                NavigationLink("🗺️ Circuits") { F1CircuitListView() }
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.title3)
            }
        }

        ToolbarItem(placement: .navigationBarLeading) {
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
        #else
        ToolbarItem(placement: .primaryAction) {
            Menu {
                NavigationLink("🔴 Live Feed") { F1LiveFeedView() }
                NavigationLink("🏁 Session Detail") { F1SessionDetailView() }
                NavigationLink("📊 Telemetry") { F1TelemetryView() }
                NavigationLink("📊 Compare") { F1ComparisonView() }
                NavigationLink("🏆 Standings") { F1StandingsView() }
                NavigationLink("🏎️ Drivers") { F1DriverListView() }
                NavigationLink("🏢 Teams") { F1TeamListView() }
                NavigationLink("📅 Calendar") { F1RaceCalendarView() }
                NavigationLink("🗺️ Circuits") { F1CircuitListView() }
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.title3)
            }
        }

        ToolbarItem(placement: .automatic) {
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
        #endif
    }

    // MARK: - Loading

    @MainActor
    private func loadAll() async {
        isLoading = true
        errorMessage = nil

        let loader = F1DashboardLoader(
            f1ServiceType: F1Service.self,
            livePulseServiceType: F1LivePulseService.self,
            openF1ServiceType: F1OpenF1Service.self
        )
        loader.openF1Enabled = settings.openF1Enabled
        loader.openF1Year = 2026

        let data = await loader.loadAll()

        nextRace = data.nextRace
        lastResult = data.lastResult
        driverStandings = data.driverStandings
        constructorStandings = data.constructorStandings
        seasonRaces = data.seasonRaces
        fiaDocuments = data.fiaDocuments
        liveEventName = data.liveEventName
        liveDocCount = data.liveDocCount
        recentSessions = data.recentSessions
        errorMessage = data.errorMessage

        isLoading = false
    }
}

#Preview {
    F1DashboardView()
}
