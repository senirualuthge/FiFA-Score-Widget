import SwiftUI

struct F1DriverListView: View {
    @State private var drivers: [F1Driver] = []
    @State private var standings: [F1DriverStanding] = []
    @State private var isLoading = true
    @State private var searchText = ""
    @State private var errorMessage: String?
    
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
                        // Standings section
                        if !standings.isEmpty {
                            Section {
                                ForEach(Array(standings.enumerated()), id: \.element.id) { index, driver in
                                    DriverStandingRow(position: index + 1, standing: driver)
                                }
                            } header: {
                                HStack {
                                    Image(systemName: "trophy.fill")
                                        .foregroundStyle(.yellow)
                                    Text("Driver Standings")
                                        .font(.headline)
                                }
                            }
                        }
                        
                        // All drivers section
                        Section {
                            ForEach(filteredDrivers, id: \.id) { driver in
                                DriverRow(driver: driver)
                            }
                        } header: {
                            Text("All Drivers")
                                .font(.headline)
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .searchable(text: $searchText, prompt: "Search drivers by name")
                }
            }
        }
        .navigationTitle("Drivers")
        .task { await load() }
    }
    
    private var filteredDrivers: [F1Driver] {
        guard !searchText.isEmpty else { return drivers }
        return drivers.filter {
            $0.fullName.localizedCaseInsensitiveContains(searchText) ||
            ($0.teamId?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    @MainActor
    private func load() async {
        isLoading = true
        errorMessage = nil
        
        do {
            async let d = F1Service.fetchCurrentDrivers()
            async let s = F1Service.fetchDriverStandings()
            (drivers, standings) = try await (d, s)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - Driver Row

struct DriverRow: View {
    let driver: F1Driver
    
    var body: some View {
        HStack {
            // Driver number circle
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 40, height: 40)
                Text(driver.number ?? "")
                    .font(.caption).bold()
                    .foregroundStyle(.white)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(driver.fullName)
                    .font(.body).bold()
                HStack(spacing: 4) {
                    if let nationality = driver.nationality {
                        Text(nationality)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    if let team = driver.teamId {
                        Text("·")
                            .foregroundStyle(.white.opacity(0.3))
                        Text(team.capitalized)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
            }
            
            Spacer()
            
            Text(driver.shortName ?? "")
                .font(.caption).bold()
                .foregroundStyle(.white.opacity(0.5))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.1))
                .clipShape(Capsule())
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Standing Row

struct DriverStandingRow: View {
    let position: Int
    let standing: F1DriverStanding
    
    var body: some View {
        HStack {
            Text("\(position)")
                .font(.headline).bold()
                .foregroundStyle(medalColor(for: position))
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(standing.shortName ?? standing.driver?.surname ?? "")
                    .font(.headline)
                HStack(spacing: 4) {
                    if let nationality = standing.driver?.nationality {
                        Text(nationality)
                            .font(.caption2)
                    }
                    if let team = standing.teamId {
                        Text("· \(team.capitalized)")
                            .font(.caption2)
                    }
                }
                .foregroundStyle(.white.opacity(0.5))
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                if let wins = standing.wins, wins > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "flag.fill")
                            .font(.caption2)
                        Text("\(wins)")
                            .font(.caption)
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

#Preview {
    NavigationStack {
        F1DriverListView()
    }
}
