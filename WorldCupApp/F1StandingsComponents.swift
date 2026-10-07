import SwiftUI

// MARK: - Dashboard Podium

/// Podium-style top-3 driver standings with medals.
struct DashboardPodiumView: View {
    let drivers: [F1DriverStanding]

    var body: some View {
        HStack(spacing: 0) {
            let medals = ["🥇", "🥈", "🥉"]
            ForEach(Array(drivers.enumerated()), id: \.element.id) { idx, driver in
                VStack(spacing: 4) {
                    Text(medals[idx]).font(.title2)
                    Text(driver.shortName ?? "").font(.subheadline).bold()
                    Text("\(driver.points ?? 0) pts").font(.caption2).foregroundStyle(.yellow)
                }
                .frame(maxWidth: .infinity)
                if idx < drivers.count - 1 {
                    Divider().frame(width: 1, height: 50).background(.white.opacity(0.1))
                }
            }
        }
        .padding(.vertical, 4)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Driver Standings List

/// Compact driver standings table showing position, name, wins, and points.
struct DriverStandingsList: View {
    let standings: [F1DriverStanding]

    var body: some View {
        VStack(spacing: 4) {
            ForEach(Array(standings.enumerated()), id: \.element.id) { idx, driver in
                HStack {
                    Text("\(idx + 1)").font(.caption).bold()
                        .foregroundStyle(idx < 3 ? medalColor(idx + 1) : .white.opacity(0.4))
                        .frame(width: 20)
                    Text(driver.shortName ?? "").font(.subheadline).bold().frame(width: 32)
                    Text(driver.driver?.surname ?? "").font(.caption).foregroundStyle(.white.opacity(0.6))
                    Spacer()
                    if let w = driver.wins, w > 0 {
                        Text("\(w)W").font(.caption2).foregroundStyle(.white.opacity(0.4)).frame(width: 28)
                    }
                    Text("\(driver.points ?? 0)").font(.subheadline).bold().foregroundStyle(.yellow).frame(width: 40, alignment: .trailing)
                }
                .padding(.vertical, 2)
                if idx < standings.count - 1 {
                    Divider().background(.white.opacity(0.06))
                }
            }
        }
    }

    private func medalColor(_ pos: Int) -> Color {
        switch pos { case 1: return .yellow case 2: return .gray case 3: return .orange default: return .white.opacity(0.6) }
    }
}

// MARK: - Constructor Standings List

/// Compact constructor standings table showing position, team name, and points.
struct ConstructorStandingsList: View {
    let standings: [F1ConstructorStanding]

    var body: some View {
        VStack(spacing: 4) {
            ForEach(Array(standings.enumerated()), id: \.element.id) { idx, standing in
                HStack {
                    Text("\(idx + 1)").font(.caption).bold()
                        .foregroundStyle(idx < 3 ? medalColor(idx + 1) : .white.opacity(0.4))
                        .frame(width: 20)
                    Text(standing.team?.teamName ?? standing.teamId.capitalized)
                        .font(.subheadline).bold().lineLimit(1)
                    Spacer()
                    Text("\(standing.points ?? 0) pts").font(.subheadline).bold().foregroundStyle(.yellow)
                }
                .padding(.vertical, 2)
                if idx < standings.count - 1 {
                    Divider().background(.white.opacity(0.06))
                }
            }
        }
    }

    private func medalColor(_ pos: Int) -> Color {
        switch pos { case 1: return .yellow case 2: return .gray case 3: return .orange default: return .white.opacity(0.6) }
    }
}

#Preview("Podium - With Data") {
    DashboardPodiumView(drivers: previewDrivers)
        .padding()
        .background(Color(red: 0.08, green: 0.08, blue: 0.12))
        .preferredColorScheme(.dark)
}

#Preview("Podium - Empty") {
    DashboardPodiumView(drivers: [])
        .padding()
        .background(Color(red: 0.08, green: 0.08, blue: 0.12))
        .preferredColorScheme(.dark)
}

#Preview("Driver List - Full") {
    DriverStandingsList(standings: previewDrivers)
        .padding()
        .background(Color(red: 0.08, green: 0.08, blue: 0.12))
        .preferredColorScheme(.dark)
}

#Preview("Driver List - Empty") {
    DriverStandingsList(standings: [])
        .padding()
        .background(Color(red: 0.08, green: 0.08, blue: 0.12))
        .preferredColorScheme(.dark)
}

#Preview("Constructor List - Full") {
    ConstructorStandingsList(standings: previewConstructors)
        .padding()
        .background(Color(red: 0.08, green: 0.08, blue: 0.12))
        .preferredColorScheme(.dark)
}

#Preview("Constructor List - Empty") {
    ConstructorStandingsList(standings: [])
        .padding()
        .background(Color(red: 0.08, green: 0.08, blue: 0.12))
        .preferredColorScheme(.dark)
}

// MARK: - Preview Data

private let previewDrivers: [F1DriverStanding] = [
    F1DriverStanding(classificationId: nil, driverId: "verstappen", teamId: "red_bull", points: 120, position: 1, wins: 5, driver: F1StandingDriverInfo(name: "Max", surname: "Verstappen", shortName: "VER", nationality: "Dutch", birthday: nil, number: 1, url: nil)),
    F1DriverStanding(classificationId: nil, driverId: "hamilton", teamId: "mercedes", points: 95, position: 2, wins: 3, driver: F1StandingDriverInfo(name: "Lewis", surname: "Hamilton", shortName: "HAM", nationality: "British", birthday: nil, number: 44, url: nil)),
    F1DriverStanding(classificationId: nil, driverId: "leclerc", teamId: "ferrari", points: 82, position: 3, wins: 2, driver: F1StandingDriverInfo(name: "Charles", surname: "Leclerc", shortName: "LEC", nationality: "Monegasque", birthday: nil, number: 16, url: nil)),
    F1DriverStanding(classificationId: nil, driverId: "norris", teamId: "mclaren", points: 68, position: 4, wins: 1, driver: F1StandingDriverInfo(name: "Lando", surname: "Norris", shortName: "NOR", nationality: "British", birthday: nil, number: 4, url: nil)),
    F1DriverStanding(classificationId: nil, driverId: "sainz", teamId: "ferrari", points: 55, position: 5, wins: 0, driver: F1StandingDriverInfo(name: "Carlos", surname: "Sainz", shortName: "SAI", nationality: "Spanish", birthday: nil, number: 55, url: nil)),
]

private let previewConstructors: [F1ConstructorStanding] = [
    F1ConstructorStanding(classificationId: 1, teamId: "red_bull", points: 250, position: 1, wins: 7, team: F1TeamStandingInfo(teamName: "Red Bull Racing", country: "Austrian", firstAppareance: 2005, constructorsChampionships: 6, driversChampionships: 4, url: nil)),
    F1ConstructorStanding(classificationId: 2, teamId: "mercedes", points: 190, position: 2, wins: 5, team: F1TeamStandingInfo(teamName: "Mercedes", country: "German", firstAppareance: 1970, constructorsChampionships: 8, driversChampionships: 7, url: nil)),
    F1ConstructorStanding(classificationId: 3, teamId: "ferrari", points: 160, position: 3, wins: 3, team: F1TeamStandingInfo(teamName: "Ferrari", country: "Italian", firstAppareance: 1950, constructorsChampionships: 16, driversChampionships: 15, url: nil)),
    F1ConstructorStanding(classificationId: 4, teamId: "mclaren", points: 110, position: 4, wins: 1, team: F1TeamStandingInfo(teamName: "McLaren", country: "British", firstAppareance: 1966, constructorsChampionships: 8, driversChampionships: 12, url: nil)),
]
