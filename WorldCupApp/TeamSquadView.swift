import SwiftUI

struct TeamSquadView: View {
    @State private var teams: [TeamDetail] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var searchText = ""
    @State private var selectedTeam: String?
    @State private var selectedPosition: String?

    var body: some View {
        ZStack {
            WorldCupWallpaper()

            Group {
                if isLoading {
                    ProgressView("Loading squads…")
                        .tint(.white)
                        .foregroundStyle(.white)
                } else if let errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                        Text(errorMessage)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            Task { await load() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .foregroundStyle(.white.opacity(0.8))
                    .padding()
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 16)], spacing: 16, pinnedViews: [.sectionHeaders]) {
                            ForEach(filteredTeams, id: \.id) { team in
                                Section {
                                    ForEach(team.squad ?? []) { player in
                                        PlayerCard(player: player, teamName: team.displayName)
                                    }
                                } header: {
                                    HStack {
                                        Text(flagEmoji(for: team.displayName))
                                            .font(.title2)
                                        Text(team.displayName)
                                            .font(.title2).bold()
                                        Spacer()
                                    }
                                    .foregroundColor(.white)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 16)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.black.opacity(0.8))
                                    )
                                    .padding(.horizontal, -16)
                                    .padding(.top, 8)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .id("\(selectedTeam ?? "all")-\(selectedPosition ?? "all")-\(searchText)")
                    }
                    .searchable(text: $searchText, prompt: "Search players or teams")
                    .refreshable {
                        await load()
                    }
                }
            }
        }
        .navigationTitle("Squads")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Menu {
                    Menu("By Team") {
                        ForEach(teams.map { $0.displayName }, id: \.self) { team in
                            Button(team) { selectedTeam = team }
                        }
                    }
                    Menu("By Position") {
                        ForEach(allPositions, id: \.self) { pos in
                            Button(pos) { selectedPosition = pos }
                        }
                    }
                    if selectedTeam != nil || selectedPosition != nil {
                        Button(role: .destructive, action: {
                            selectedTeam = nil
                            selectedPosition = nil
                        }) {
                            Label("Clear Filters", systemImage: "xmark.circle")
                        }
                    }
                } label: {
                    Image(systemName: selectedTeam != nil || selectedPosition != nil ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                }
            }
        }
        .task { await load() }
    }

    private var allPositions: [String] {
        let positions = teams.flatMap { $0.squad ?? [] }.compactMap { $0.position }
        return Array(Set(positions)).sorted()
    }

    private var filteredTeams: [TeamDetail] {
        var result = teams

        if let selectedTeam {
            result = result.filter { $0.displayName == selectedTeam }
        }

        return result.compactMap { team in
            var squad = team.squad ?? []
            
            if let selectedPosition {
                squad = squad.filter { $0.position == selectedPosition }
            }

            if !searchText.isEmpty {
                let teamMatches = team.displayName.localizedCaseInsensitiveContains(searchText)
                squad = squad.filter {
                    $0.name.localizedCaseInsensitiveContains(searchText) || teamMatches
                }
                if !teamMatches && squad.isEmpty { return nil }
            } else if squad.isEmpty {
                return nil
            }

            return TeamDetail(
                id: team.id,
                name: team.name,
                shortName: team.shortName,
                crest: team.crest,
                squad: squad
            )
        }
    }

    @MainActor
    private func load() async {
        isLoading = true
        errorMessage = nil
        
        do {
            teams = try await WorldCupService.fetchAllSquads()
                .sorted { $0.displayName < $1.displayName }
        } catch {
            errorMessage = "Couldn't load squads: \(error.localizedDescription)"
        }
        isLoading = false
    }
}

private struct PlayerCard: View {
    let player: SquadPlayer
    let teamName: String

    var body: some View {
        VStack(spacing: 8) {
            Text(player.name)
                .font(.headline)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .foregroundColor(.white)
            
            VStack(spacing: 4) {
                Text(player.positionLabel)
                    .font(.caption)
                    .textCase(.uppercase)
                    .foregroundColor(.white.opacity(0.6))
                
                HStack(spacing: 4) {
                    Text(flagEmoji(for: teamName))
                    Text(teamName)
                }
                .font(.caption2)
                .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.12, green: 0.35, blue: 0.20).opacity(0.35),
                            Color.white.opacity(0.06)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.20, green: 0.60, blue: 0.35).opacity(0.5),
                                    Color.white.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
}

private func flagEmoji(for country: String) -> String {
    let mapping: [String: String] = [
        // Group A
        "United States": "🇺🇸", "USA": "🇺🇸",
        "Mexico": "🇲🇽",
        "Panama": "🇵🇦",
        "Cuba": "🇨🇺",
        // Group B
        "Uruguay": "🇺🇾",
        "Canada": "🇨🇦",
        "Bolivia": "🇧🇴",
        // Group C
        "Argentina": "🇦🇷",
        "Chile": "🇨🇱",
        "Peru": "🇵🇪",
        // Group D
        "Brazil": "🇧🇷",
        "Colombia": "🇨🇴",
        "Paraguay": "🇵🇾",
        "Ecuador": "🇪🇨",
        // Group E
        "France": "🇫🇷",
        "Belgium": "🇧🇪",
        "Croatia": "🇭🇷",
        // Group F
        "Spain": "🇪🇸",
        "Portugal": "🇵🇹",
        "Morocco": "🇲🇦",
        // Group G
        "Germany": "🇩🇪",
        "Netherlands": "🇳🇱",
        "Japan": "🇯🇵",
        "Australia": "🇦🇺",
        // Group H
        "England": "🏴󠁧󠁢󠁥󠁮󠁧󠁿",
        "Senegal": "🇸🇳",
        "Serbia": "🇷🇸",
        "South Africa": "🇿🇦",
        // Group I
        "Italy": "🇮🇹",
        "Saudi Arabia": "🇸🇦",
        "Nigeria": "🇳🇬",
        // Group J
        "South Korea": "🇰🇷",
        "Algeria": "🇩🇿",
        "Cameroon": "🇨🇲",
        // Group K
        "Iran": "🇮🇷",
        "China": "🇨🇳",
        "Qatar": "🇶🇦",
        // Group L
        "Switzerland": "🇨🇭",
        "Costa Rica": "🇨🇷",
        "Honduras": "🇭🇳",
        // Others
        "Denmark": "🇩🇰", "Poland": "🇵🇱", "Türkiye": "🇹🇷", "Turkey": "🇹🇷",
        "Ghana": "🇬🇭", "Tunisia": "🇹🇳", "Egypt": "🇪🇬",
        "New Zealand": "🇳🇿", "Indonesia": "🇮🇩", "Venezuela": "🇻🇪",
        "Czechia": "🇨🇿", "Czech Republic": "🇨🇿", "Slovakia": "🇸🇰",
        "Scotland": "🏴󠁧󠁢󠁳󠁣󠁴󠁿", "Wales": "🏴󠁧󠁢󠁷󠁬󠁳󠁿", "Greece": "🇬🇷",
        "Norway": "🇳🇴", "Sweden": "🇸🇪", "Austria": "🇦🇹",
        "Jordan": "🇯🇴", "Korea Republic": "🇰🇷", "Korea": "🇰🇷",
    ]
    return mapping[country] ?? "🏳️"
}

#Preview {
    NavigationStack {
        TeamSquadView()
    }
}
