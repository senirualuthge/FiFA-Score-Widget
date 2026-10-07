import SwiftUI

struct F1StandingsView: View {
    @State private var selectedTab: StandingTab = .drivers
    @State private var driverStandings: [F1DriverStanding] = []
    @State private var constructorStandings: [F1ConstructorStanding] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var searchText = ""
    
    enum StandingTab: String, CaseIterable {
        case drivers = "Drivers"
        case constructors = "Constructors"
    }
    
    var body: some View {
        ZStack {
            F1Wallpaper()
            
            Group {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else if let errorMessage {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                        Text(errorMessage).foregroundStyle(.white.opacity(0.8))
                        Button("Retry") { Task { await load() } }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    VStack(spacing: 0) {
                        // Custom Segmented Picker
                        Picker("Standings", selection: $selectedTab) {
                            ForEach(StandingTab.allCases, id: \.self) { tab in
                                Text(tab.rawValue).tag(tab)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.3))
                        
                        // Content
                        if selectedTab == .drivers {
                            driverStandingsList
                        } else {
                            constructorStandingsList
                        }
                    }
                }
            }
        }
        .navigationTitle("Standings")
        .task { await load() }
    }
    
    // MARK: - Driver Standings
    
    private var driverStandingsList: some View {
        List {
            // Podium top 3
            if driverStandings.count >= 3 {
                Section {
                    PodiumView(top3: Array(driverStandings.prefix(3)))
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
            }
            
            // Full standings
            Section {
                ForEach(Array(filteredDriverStandings.enumerated()), id: \.element.id) { index, standing in
                    DriverStandingDetailRow(position: index + 1, standing: standing)
                }
            } header: {
                HStack {
                    Text("Pos")
                        .frame(width: 32, alignment: .leading)
                    Text("Driver")
                    Spacer()
                    if selectedTab == .drivers {
                        Text("Wins")
                            .frame(width: 40, alignment: .trailing)
                    }
                    Text("Pts")
                        .frame(width: 50, alignment: .trailing)
                }
                .font(.caption).bold()
                .foregroundStyle(.white.opacity(0.5))
            }
        }
        .scrollContentBackground(.hidden)
        .searchable(text: $searchText, prompt: "Search drivers")
    }
    
    private var filteredDriverStandings: [F1DriverStanding] {
        guard !searchText.isEmpty else { return driverStandings }
        return driverStandings.filter {
            ($0.driver?.name?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            ($0.driver?.surname?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            ($0.teamId?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    // MARK: - Constructor Standings
    
    private var constructorStandingsList: some View {
        let sorted = constructorStandings.sorted { ($0.position ?? 99) < ($1.position ?? 99) }
        
        return List {
            // Podium top 3
            if sorted.count >= 3 {
                Section {
                    ConstructorPodiumView(top3: Array(sorted.prefix(3)))
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
            }
            
            // Full standings
            Section {
                ForEach(Array(sorted.enumerated()), id: \.element.id) { index, standing in
                    ConstructorStandingDetailRow(position: index + 1, standing: standing)
                }
            } header: {
                HStack {
                    Text("Pos")
                        .frame(width: 32, alignment: .leading)
                    Text("Constructor")
                    Spacer()
                    Text("Wins")
                        .frame(width: 40, alignment: .trailing)
                    Text("Pts")
                        .frame(width: 50, alignment: .trailing)
                }
                .font(.caption).bold()
                .foregroundStyle(.white.opacity(0.5))
            }
        }
        .scrollContentBackground(.hidden)
    }
    
    @MainActor
    private func load() async {
        isLoading = true
        errorMessage = nil
        
        do {
            async let d = F1Service.fetchDriverStandings(year: nil)
            async let c = F1Service.fetchConstructorStandings(year: nil)
            (driverStandings, constructorStandings) = try await (d, c)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - Driver Standings List Row

struct DriverStandingDetailRow: View {
    let position: Int
    let standing: F1DriverStanding
    @State private var isHighlighted = false
    
    var body: some View {
        HStack {
            // Position
            Text("\(position)")
                .font(.headline).bold()
                .foregroundStyle(position <= 3 ? medalColor(for: position) : .white.opacity(0.5))
                .frame(width: 32)
            
            // Driver info
            VStack(alignment: .leading, spacing: 2) {
                Text(standing.shortName ?? standing.driver?.surname ?? "")
                    .font(.headline)
                if let team = standing.teamId {
                    Text(team.capitalized)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
            
            Spacer()
            
            // Wins
            if let wins = standing.wins {
                Text("\(wins)")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(width: 40, alignment: .trailing)
            }
            
            // Points
            Text("\(standing.points ?? 0)")
                .font(.title3).bold()
                .foregroundStyle(.yellow)
                .frame(width: 50, alignment: .trailing)
        }
        .padding(.vertical, 4)
        .opacity(isHighlighted ? 1.0 : 0.0)
        .animation(.easeIn(duration: 0.3).delay(Double(position) * 0.03), value: isHighlighted)
        .onAppear { isHighlighted = true }
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

// MARK: - Constructor Standings List Row

struct ConstructorStandingDetailRow: View {
    let position: Int
    let standing: F1ConstructorStanding
    @State private var isHighlighted = false
    
    var body: some View {
        HStack {
            Text("\(position)")
                .font(.headline).bold()
                .foregroundStyle(position <= 3 ? medalColor(for: position) : .white.opacity(0.5))
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(standing.team?.teamName ?? standing.teamId.capitalized)
                    .font(.headline)
                if let country = standing.team?.country {
                    Text(country)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
            
            Spacer()
            
            if let wins = standing.wins {
                Text("\(wins)")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(width: 40, alignment: .trailing)
            }
            
            Text("\(standing.points ?? 0)")
                .font(.title3).bold()
                .foregroundStyle(.yellow)
                .frame(width: 50, alignment: .trailing)
        }
        .padding(.vertical, 4)
        .opacity(isHighlighted ? 1.0 : 0.0)
        .animation(.easeIn(duration: 0.3).delay(Double(position) * 0.03), value: isHighlighted)
        .onAppear { isHighlighted = true }
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

// MARK: - Podium View (Drivers)

struct PodiumView: View {
    let top3: [F1DriverStanding]
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .bottom, spacing: 12) {
                // 2nd place (left)
                if top3.count >= 2 {
                    podiumStep(position: 2, driver: top3[1], height: 80)
                }
                // 1st place (center, highest)
                if !top3.isEmpty {
                    podiumStep(position: 1, driver: top3[0], height: 110)
                }
                // 3rd place (right)
                if top3.count >= 3 {
                    podiumStep(position: 3, driver: top3[2], height: 60)
                }
            }
        }
        .padding(.vertical)
    }
    
    private func podiumStep(position: Int, driver: F1DriverStanding, height: CGFloat) -> some View {
        VStack(spacing: 8) {
            Text(driver.shortName ?? "")
                .font(.headline).bold()
            Text("\(driver.points ?? 0)")
                .font(.caption).bold()
                .foregroundStyle(.yellow)
            
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(podiumColor(for: position))
                    .frame(height: height)
                Text(["🥇", "🥈", "🥉"][position - 1])
                    .font(.title)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private func podiumColor(for position: Int) -> Color {
        switch position {
        case 1: return .yellow.opacity(0.3)
        case 2: return .gray.opacity(0.3)
        case 3: return .orange.opacity(0.3)
        default: return .clear
        }
    }
}

// MARK: - Podium View (Constructors)

struct ConstructorPodiumView: View {
    let top3: [F1ConstructorStanding]
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .bottom, spacing: 12) {
                if top3.count >= 2 {
                    constructorPodiumStep(position: 2, standing: top3[1], height: 80)
                }
                if !top3.isEmpty {
                    constructorPodiumStep(position: 1, standing: top3[0], height: 110)
                }
                if top3.count >= 3 {
                    constructorPodiumStep(position: 3, standing: top3[2], height: 60)
                }
            }
        }
        .padding(.vertical)
    }
    
    private func constructorPodiumStep(position: Int, standing: F1ConstructorStanding, height: CGFloat) -> some View {
        VStack(spacing: 8) {
            Text(standing.team?.teamName ?? standing.teamId.capitalized)
                .font(.caption).bold()
                .multilineTextAlignment(.center)
                .lineLimit(2)
            Text("\(standing.points ?? 0)")
                .font(.caption).bold()
                .foregroundStyle(.yellow)
            
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(podiumColor(for: position))
                    .frame(height: height)
                Text(["🥇", "🥈", "🥉"][position - 1])
                    .font(.title)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private func podiumColor(for position: Int) -> Color {
        switch position {
        case 1: return .yellow.opacity(0.3)
        case 2: return .gray.opacity(0.3)
        case 3: return .orange.opacity(0.3)
        default: return .clear
        }
    }
}

#Preview {
    NavigationStack {
        F1StandingsView()
    }
}
