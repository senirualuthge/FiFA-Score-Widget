import SwiftUI

/// Card showing the last race result with top-3 podium finishers.
struct LastRaceCard: View {
    let result: F1RaceResult

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "flag.checkered")
                    .font(.title3)
                    .foregroundStyle(.red)
                Text("Last Race")
                    .font(.headline).bold()
                Spacer()
                if let raceName = result.raceName {
                    Text(raceName)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.3))
            }
            .foregroundStyle(.white)

            if let results = result.results?.prefix(3) {
                ForEach(Array(results), id: \.position) { entry in
                    HStack {
                        Text("#\(entry.position ?? 0)")
                            .font(.caption).bold()
                            .foregroundStyle(positionColor(entry.position ?? 0))
                            .frame(width: 24)
                        Text(entry.driver?.shortName ?? "")
                            .font(.subheadline).bold()
                            .frame(width: 36)
                        Text(entry.driver?.surname ?? "")
                            .font(.subheadline)
                        Spacer()
                        if let team = entry.team?.teamName {
                            Text(team)
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.5))
                                .lineLimit(1)
                        }
                        if let points = entry.points {
                            Text("\(points)pts")
                                .font(.caption).bold()
                                .foregroundStyle(.yellow)
                                .frame(width: 40, alignment: .trailing)
                        }
                    }
                    .padding(.vertical, 2)
                    if entry.position ?? 0 < min(3, result.results?.count ?? 3) {
                        Divider().background(.white.opacity(0.06))
                    }
                }
            }

            HStack {
                Spacer()
                Text("Tap for full session detail →")
                    .font(.caption2)
                    .foregroundStyle(.red.opacity(0.7))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.red.opacity(0.15), lineWidth: 1)
                )
        )
    }

    private func positionColor(_ pos: Int) -> Color {
        switch pos {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .white.opacity(0.5)
        }
    }
}

#Preview("With Results") {
    LastRaceCard(result: F1RaceResult(
        raceId: "1", round: 6,
        raceName: "Austrian Grand Prix",
        date: "2026-07-05", time: "14:00:00Z",
        circuit: F1Circuit(circuitId: "red_bull_ring", circuitName: "Red Bull Ring", country: "Austria", city: "Spielberg", circuitLength: "4.318", lapRecord: nil, corners: nil, firstParticipationYear: nil, url: nil),
        results: [
            F1RaceResultEntry(driver: F1ResultDriver(driverId: "verstappen", name: "Max", surname: "Verstappen", shortName: "VER", number: 1, nationality: "Dutch"), team: F1ResultTeam(teamId: "red_bull", teamName: "Red Bull Racing", nationality: "Austrian"), points: 25, time: "1:28:45.123", retired: nil, fastLap: "1:07.234", positionRaw: "1"),
            F1RaceResultEntry(driver: F1ResultDriver(driverId: "norris", name: "Lando", surname: "Norris", shortName: "NOR", number: 4, nationality: "British"), team: F1ResultTeam(teamId: "mclaren", teamName: "McLaren", nationality: "British"), points: 18, time: "1:29:02.456", retired: nil, fastLap: nil, positionRaw: "2"),
            F1RaceResultEntry(driver: F1ResultDriver(driverId: "hamilton", name: "Lewis", surname: "Hamilton", shortName: "HAM", number: 44, nationality: "British"), team: F1ResultTeam(teamId: "mercedes", teamName: "Mercedes", nationality: "German"), points: 15, time: "1:29:15.789", retired: nil, fastLap: nil, positionRaw: "3"),
        ]
    ))
    .padding()
    .background(Color(red: 0.08, green: 0.08, blue: 0.12))
    .preferredColorScheme(.dark)
}

#Preview("No Results") {
    LastRaceCard(result: F1RaceResult(
        raceId: "1", round: 6,
        raceName: "Austrian Grand Prix",
        date: nil, time: nil,
        circuit: nil, results: nil
    ))
    .padding()
    .background(Color(red: 0.08, green: 0.08, blue: 0.12))
    .preferredColorScheme(.dark)
}
