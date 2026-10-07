import SwiftUI

/// Race Hub tab — shows the next race, last result, quick stats, live document feed, and quick links.
struct F1OverviewTab: View {
    let nextRace: F1Race?
    let lastResult: F1RaceResult?
    let driverStandings: [F1DriverStanding]
    let constructorStandings: [F1ConstructorStanding]
    let seasonRaces: [F1Race]
    let fiaDocuments: [FIADocument]
    let liveDocCount: Int

    let refreshAction: () async -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Next Race Card (tappable to calendar)
                if let nextRace {
                    NavigationLink {
                        F1RaceCalendarView()
                    } label: {
                        NextRaceCard(race: nextRace)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                }

                // Last Race + Session Detail combo
                if let lastResult {
                    NavigationLink {
                        F1SessionDetailView()
                    } label: {
                        LastRaceCard(result: lastResult)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                }

                // Quick Stats Row
                HStack(spacing: 12) {
                    if !driverStandings.isEmpty {
                        NavigationLink {
                            F1StandingsView()
                        } label: {
                            QuickStatCard(
                                title: "Drivers",
                                value: "\(driverStandings.count)",
                                subtitle: "\(driverStandings.first?.shortName ?? "") leads",
                                icon: "person.3.fill",
                                color: .yellow
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    if !constructorStandings.isEmpty {
                        NavigationLink {
                            F1StandingsView()
                        } label: {
                            QuickStatCard(
                                title: "Constructors",
                                value: "\(constructorStandings.count)",
                                subtitle: constructorStandings.first?.team?.teamName ?? "",
                                icon: "building.2.fill",
                                color: .blue
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    NavigationLink {
                        F1RaceCalendarView()
                    } label: {
                        QuickStatCard(
                            title: "Races",
                            value: "\(seasonRaces.count)",
                            subtitle: "2026 season",
                            icon: "flag.checkered",
                            color: .green
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)

                // Live Feed Summary (latest 3 documents inline)
                if !fiaDocuments.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .foregroundStyle(.red)
                            Text("Latest Documents")
                                .font(.headline).bold()
                            Spacer()
                            NavigationLink("See All \(liveDocCount) →") {
                                F1LiveFeedView()
                            }
                            .font(.caption)
                            .foregroundStyle(.red)
                        }
                        .foregroundStyle(.white)

                        ForEach(Array(fiaDocuments.prefix(3))) { doc in
                            NavigationLink {
                                if doc.isRaceClassification || doc.isChampionshipPoints {
                                    F1SessionDetailView()
                                } else {
                                    F1LiveFeedView()
                                }
                            } label: {
                                LiveFeedMiniCard(document: doc)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }

                // Quick Links Grid
                quickLinksGrid
                    .padding(.horizontal)

                // Data attribution
                HStack(spacing: 12) {
                    Text("f1api.dev")
                    if !fiaDocuments.isEmpty { Text("F1 Live Pulse") }
                    Text("OpenF1")
                }
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.25))
                .padding(.bottom, 20)
            }
            .padding(.vertical)
        }
        .refreshable { await refreshAction() }
    }

    // MARK: - Quick Links Grid

    private var quickLinksGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            MiniNavCard(title: "Live Feed", icon: "antenna.radiowaves.left.and.right", color: .red) { F1LiveFeedView() }
            MiniNavCard(title: "Session", icon: "flag.checkered", color: .pink) { F1SessionDetailView() }
            MiniNavCard(title: "Telemetry", icon: "chart.xyaxis.line", color: .purple) { F1TelemetryView() }
            MiniNavCard(title: "Compare", icon: "arrow.left.arrow.right", color: .mint) { F1ComparisonView() }
            MiniNavCard(title: "Standings", icon: "trophy.fill", color: .yellow) { F1StandingsView() }
            MiniNavCard(title: "Calendar", icon: "calendar", color: .green) { F1RaceCalendarView() }
            MiniNavCard(title: "Drivers", icon: "person.3.fill", color: .red) { F1DriverListView() }
            MiniNavCard(title: "Teams", icon: "building.2.fill", color: .blue) { F1TeamListView() }
            MiniNavCard(title: "Circuits", icon: "map.fill", color: .orange) { F1CircuitListView() }
        }
    }
}

#Preview {
    NavigationStack {
        F1OverviewTab(
            nextRace: nil,
            lastResult: nil,
            driverStandings: [],
            constructorStandings: [],
            seasonRaces: [],
            fiaDocuments: [],
            liveDocCount: 0,
            refreshAction: {}
        )
        .preferredColorScheme(.dark)
    }
}
