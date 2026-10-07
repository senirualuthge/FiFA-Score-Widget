import SwiftUI

struct F1TeamListView: View {
    @State private var teams: [F1Team] = []
    @State private var constructorStandings: [F1ConstructorStanding] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedTeam: F1Team?
    @State private var teamDrivers: [F1Driver] = []
    
    var body: some View {
        ZStack {
            F1Wallpaper()
            
            Group {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else if let errorMessage {
                    VStack(spacing: 12) {
                        Text(errorMessage).foregroundStyle(.white.opacity(0.8))
                        Button("Retry") { Task { await load() } }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        // Constructor standings
                        if !constructorStandings.isEmpty {
                            Section {
                                ForEach(constructorStandings.sorted(by: { ($0.position ?? 99) < ($1.position ?? 99) }), id: \.id) { standing in
                                    ConstructorStandingRow(standing: standing)
                                }
                            } header: {
                                HStack {
                                    Image(systemName: "building.2.fill")
                                        .foregroundStyle(.blue)
                                    Text("Constructor Standings")
                                        .font(.headline)
                                }
                            }
                        }
                        
                        // All teams
                        Section {
                            ForEach(teams, id: \.id) { team in
                                Button {
                                    selectedTeam = team
                                    Task { await loadTeamDrivers(teamId: team.teamId) }
                                } label: {
                                    TeamRow(team: team)
                                }
                                .buttonStyle(.plain)
                            }
                        } header: {
                            Text("Constructors")
                                .font(.headline)
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .navigationTitle("Teams")
        .sheet(item: $selectedTeam) { team in
            TeamDetailSheet(team: team, drivers: teamDrivers)
        }
        .task { await load() }
    }
    
    @MainActor
    private func load() async {
        isLoading = true
        errorMessage = nil
        
        do {
            async let t = F1Service.fetchCurrentTeams()
            async let s = F1Service.fetchConstructorStandings()
            (teams, constructorStandings) = try await (t, s)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    @MainActor
    private func loadTeamDrivers(teamId: String) async {
        teamDrivers = (try? await F1Service.fetchTeamDrivers(teamId: teamId)) ?? []
    }
}

// MARK: - Team Row

struct TeamRow: View {
    let team: F1Team
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(team.teamName ?? team.teamId.capitalized)
                    .font(.body).bold()
                    .foregroundStyle(.white)
                HStack(spacing: 8) {
                    if let nat = team.teamNationality {
                        Text(nat)
                            .font(.caption)
                    }
                    if let first = team.firstAppeareance {
                        Text("Since \(first)")
                            .font(.caption)
                    }
                }
                .foregroundStyle(.white.opacity(0.5))
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                if let cc = team.constructorsChampionships {
                    HStack(spacing: 2) {
                        Image(systemName: "trophy.fill")
                            .font(.caption2)
                        Text("\(cc)")
                    }
                    .foregroundStyle(.yellow.opacity(0.7))
                }
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.3))
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Constructor Standing Row

struct ConstructorStandingRow: View {
    let standing: F1ConstructorStanding
    
    var body: some View {
        HStack {
            Text("\(standing.position ?? 0)")
                .font(.headline).bold()
                .foregroundStyle(medalColor(for: standing.position ?? 0))
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(standing.team?.teamName ?? standing.teamId.capitalized)
                    .font(.headline)
                if let country = standing.team?.country {
                    Text(country)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                if let wins = standing.wins, wins > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "flag.fill")
                            .font(.caption2)
                        Text("\(wins)")
                    }
                    .foregroundStyle(.white.opacity(0.5))
                }
                Text("\(standing.points ?? 0)")
                    .font(.title3).bold()
                    .foregroundStyle(.yellow)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func medalColor(for position: Int) -> Color {
        switch position {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .white.opacity(0.6)
        }
    }
}

// MARK: - Team Detail Sheet

struct TeamDetailSheet: View {
    let team: F1Team
    let drivers: [F1Driver]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            F1Wallpaper()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(team.teamName ?? team.teamId.capitalized)
                            .font(.largeTitle).bold()
                        if let nat = team.teamNationality {
                            Text(nat)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                .padding()
                
                // Stats
                HStack(spacing: 20) {
                    StatBadge(label: "Constructors", value: "\(team.constructorsChampionships ?? 0)")
                    StatBadge(label: "Drivers", value: "\(team.driversChampionships ?? 0)")
                    if let debut = team.firstAppeareance {
                        StatBadge(label: "Debut", value: "\(debut)")
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
                
                // Drivers
                if !drivers.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current Drivers")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(drivers, id: \.id) { driver in
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.1))
                                        .frame(width: 36, height: 36)
                                    Text(driver.number ?? "")
                                        .font(.caption).bold()
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(driver.fullName)
                                        .font(.body).bold()
                                    Text(driver.nationality ?? "")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.5))
                                }
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(.top)
                }
                
                Spacer()
            }
        }
    }
}

struct StatBadge: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2).bold()
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    NavigationStack {
        F1TeamListView()
    }
}
