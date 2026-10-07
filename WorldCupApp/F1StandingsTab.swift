import SwiftUI

/// Standings tab — shows driver championship (podium + list) and constructor championship previews.
struct F1StandingsTab: View {
    let driverStandings: [F1DriverStanding]
    let constructorStandings: [F1ConstructorStanding]

    let refreshAction: () async -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if !driverStandings.isEmpty {
                    driverSection
                }
                if !constructorStandings.isEmpty {
                    constructorSection
                }
                HStack(spacing: 12) {
                    NavPill(title: "Full Standings", icon: "trophy.fill", color: .yellow) { F1StandingsView() }
                    NavPill(title: "Drivers", icon: "person.3.fill", color: .red) { F1DriverListView() }
                    NavPill(title: "Teams", icon: "building.2.fill", color: .blue) { F1TeamListView() }
                }
                .padding(.horizontal)
                Spacer()
            }
            .padding(.vertical)
        }
        .refreshable { await refreshAction() }
    }

    // MARK: - Driver Section

    private var driverSection: some View {
        NavigationLink {
            F1StandingsView()
        } label: {
            driverCard
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
    }

    private var driverCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "trophy.fill").foregroundStyle(.yellow)
                Text("Drivers Championship").font(.headline).bold()
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.white.opacity(0.3))
            }
            DashboardPodiumView(drivers: Array(driverStandings.prefix(3)))
            DriverStandingsList(standings: Array(driverStandings.prefix(8)))
            if driverStandings.count >= 2 {
                let gap = (driverStandings[0].points ?? 0) - (driverStandings[1].points ?? 0)
                Text("Leader leads by \(gap) pts →").font(.caption2).foregroundStyle(.yellow.opacity(0.7))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.yellow.opacity(0.2), lineWidth: 1)
                )
        )
    }

    // MARK: - Constructor Section

    private var constructorSection: some View {
        let sorted = constructorStandings.sorted { ($0.position ?? 99) < ($1.position ?? 99) }
        return NavigationLink {
            F1StandingsView()
        } label: {
            constructorCard(sorted: sorted)
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
    }

    private func constructorCard(sorted: [F1ConstructorStanding]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "building.2.fill").foregroundStyle(.blue)
                Text("Constructors Championship").font(.headline).bold()
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.white.opacity(0.3))
            }
            ConstructorStandingsList(standings: Array(sorted.prefix(5)))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

#Preview {
    NavigationStack {
        F1StandingsTab(
            driverStandings: [],
            constructorStandings: [],
            refreshAction: {}
        )
        .preferredColorScheme(.dark)
    }
}
