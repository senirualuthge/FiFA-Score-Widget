import SwiftUI

struct F1RaceCalendarView: View {
    @State private var races: [F1Race] = []
    @State private var nextRace: F1Race?
    @State private var lastRace: F1Race?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedRace: F1Race?

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
                        // Next race highlight
                        if let nextRace {
                            Section {
                                NextRaceHighlightCard(race: nextRace)
                                    .listRowInsets(EdgeInsets())
                                    .listRowBackground(Color.clear)
                            } header: {
                                HStack {
                                    Image(systemName: "flag.checkered.2.crossed")
                                        .foregroundStyle(.red)
                                    Text("UPCOMING")
                                }
                                .font(.headline)
                            }
                        }

                        // Last result
                        if let lastRace {
                            Section {
                                RaceCard(race: lastRace)
                                    .listRowInsets(EdgeInsets())
                                    .listRowBackground(Color.clear)
                            } header: {
                                HStack {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .foregroundStyle(.white.opacity(0.6))
                                    Text("LAST RACE")
                                }
                                .font(.headline)
                            }
                        }

                        // Full calendar
                        Section {
                            ForEach(races, id: \.id) { race in
                                Button {
                                    selectedRace = race
                                } label: {
                                    RaceCard(race: race)
                                }
                                .buttonStyle(.plain)
                                .listRowInsets(EdgeInsets())
                                .listRowBackground(Color.clear)
                            }
                        } header: {
                            HStack {
                                Image(systemName: "calendar")
                                Text("2026 SEASON")
                            }
                            .font(.headline)
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .navigationTitle("Calendar")
        .sheet(item: $selectedRace) { race in
            RaceDetailSheet(race: race)
        }
        .task { await load() }
    }

    @MainActor
    private func load() async {
        isLoading = true
        errorMessage = nil

        do {
            async let r = F1Service.fetchCurrentSeason()
            async let n = F1Service.fetchNextRace()
            async let l = F1Service.fetchLastRace()

            (races, nextRace, lastRace) = try await (r, n, l)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - Race Card

struct RaceCard: View {
    let race: F1Race

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(race.roundLabel)
                    .font(.caption).bold()
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.red.opacity(0.3))
                    .clipShape(Capsule())

                Spacer()

                if let date = race.raceDateString {
                    Text(date)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }

            Text(race.raceName ?? "")
                .font(.headline).bold()
                .foregroundStyle(.white)

            if let circuit = race.circuit {
                HStack(spacing: 4) {
                    Image(systemName: "mappin")
                        .font(.caption2)
                    Text(circuit.location)
                        .font(.subheadline)
                }
                .foregroundStyle(.white.opacity(0.6))
            }

            if let winner = race.winner {
                HStack(spacing: 4) {
                    Image(systemName: "trophy.fill")
                        .font(.caption2)
                        .foregroundStyle(.yellow)
                    Text("Winner: \(winner.name ?? "") \(winner.surname ?? "")")
                        .font(.caption)
                }
                .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding()
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.vertical, 4)
    }
}

// MARK: - Next Race Highlight

struct NextRaceHighlightCard: View {
    let race: F1Race

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "flag.checkered.2.crossed")
                    .font(.title2)
                    .foregroundStyle(.red)
                Text("Next Race")
                    .font(.title3).bold()
                Spacer()
                Text(race.roundLabel)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.3))
                    .clipShape(Capsule())
            }

            Text(race.raceName ?? "")
                .font(.title2).bold()

            if let circuit = race.circuit {
                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                    Text(circuit.location)
                }
                .foregroundStyle(.white.opacity(0.7))
            }

            HStack(spacing: 16) {
                if let date = race.raceDateString {
                    Label(date, systemImage: "calendar")
                }
                if let laps = race.laps {
                    Label("\(laps) laps", systemImage: "repeat")
                }
            }
            .font(.caption)
            .foregroundStyle(.white.opacity(0.6))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.red.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.vertical, 4)
    }
}

// MARK: - Race Detail Sheet

struct RaceDetailSheet: View {
    let race: F1Race
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            F1Wallpaper()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(race.roundLabel)
                                .font(.caption).bold()
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.red.opacity(0.3))
                                .clipShape(Capsule())
                            Text(race.raceName ?? "")
                                .font(.largeTitle).bold()
                                .padding(.top, 4)
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

                    // Circuit info
                    if let circuit = race.circuit {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(circuit.circuitName ?? "")
                                .font(.title2).bold()

                            HStack(spacing: 4) {
                                Image(systemName: "mappin")
                                Text(circuit.location)
                            }
                            .foregroundStyle(.white.opacity(0.7))

                            HStack(spacing: 16) {
                                if let length = circuit.circuitLength {
                                    StatBadge(label: "Length", value: "\(length) km")
                                }
                                if let corners = circuit.corners {
                                    StatBadge(label: "Corners", value: "\(corners)")
                                }
                                if let firstYear = circuit.firstParticipationYear {
                                    StatBadge(label: "Since", value: "\(firstYear)")
                                }
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Session times
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Session Schedule")
                            .font(.headline)

                        VStack(spacing: 6) {
                            SessionInfoRow(label: "Free Practice 1", session: race.fp1)
                            SessionInfoRow(label: "Free Practice 2", session: race.fp2)
                            SessionInfoRow(label: "Free Practice 3", session: race.fp3)
                            SessionInfoRow(label: "Qualifying", session: race.qualy)
                            if let sq = race.sprintQualy {
                                SessionInfoRow(label: "Sprint Qualifying", session: sq)
                            }
                            if let sr = race.sprintRace {
                                SessionInfoRow(label: "Sprint Race", session: sr)
                            }
                            Divider().background(.white.opacity(0.2))
                            SessionInfoRow(label: "\u{1F3C1} Race", session: .init(date: race.date, time: race.time))
                                .fontWeight(.bold)
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Winner
                    if let winner = race.winner {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Winner")
                                .font(.headline)
                            HStack {
                                Image(systemName: "trophy.fill")
                                    .foregroundStyle(.yellow)
                                Text("\(winner.name ?? "") \(winner.surname ?? "")")
                                    .font(.title3).bold()
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding()
            }
        }
    }
}

struct SessionInfoRow: View {
    let label: String
    let session: F1Session?

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.white.opacity(0.8))
            Spacer()
            if let date = session?.date {
                Text(formatDate(date))
                    .foregroundStyle(.white.opacity(0.6))
            }
            if let time = session?.time {
                Text(formatTime(time))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .font(.subheadline)
    }

    private func formatDate(_ date: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let d = formatter.date(from: String(date.prefix(10))) else { return date }
        formatter.dateFormat = "MMM d"
        return formatter.string(from: d)
    }

    private func formatTime(_ time: String) -> String {
        let t = time.prefix(5)
        guard t.count == 5 else { return time }
        let comps = t.split(separator: ":")
        guard comps.count == 2,
              let hour = Int(comps[0]),
              let min = Int(comps[1]) else { return time }
        let ampm = hour >= 12 ? "PM" : "AM"
        let h12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        return "\(h12):\(String(format: "%02d", min)) \(ampm)"
    }
}

#Preview {
    NavigationStack {
        F1RaceCalendarView()
    }
}
