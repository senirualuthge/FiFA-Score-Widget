import SwiftUI

// MARK: - Next Race Card

/// Expandable card showing the next F1 race with session times and event details.
struct NextRaceCard: View {
    let race: F1Race
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "flag.checkered.2.crossed")
                        .font(.title3)
                        .foregroundStyle(.red)
                    Text("Next Race")
                        .font(.headline).bold()
                        .foregroundStyle(.white)
                    Spacer()
                    Text("Round \(race.round ?? 0)")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.3))
                        .clipShape(Capsule())
                }
            }
            .buttonStyle(.plain)

            Text(race.raceName ?? "")
                .font(.title2).bold()
                .foregroundStyle(.white)

            if let circuit = race.circuit {
                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.caption)
                    Text(circuit.location)
                        .font(.subheadline)
                }
                .foregroundStyle(.white.opacity(0.7))
            }

            HStack(spacing: 16) {
                if let date = race.raceDateString {
                    Label(date, systemImage: "calendar")
                        .font(.caption)
                }
                if let time = race.time {
                    Label(time, systemImage: "clock")
                        .font(.caption)
                }
                if let laps = race.laps {
                    Label("\(laps) laps", systemImage: "repeat")
                        .font(.caption)
                }
            }
            .foregroundStyle(.white.opacity(0.6))

            if isExpanded {
                VStack(spacing: 4) {
                    SessionRow(label: "Free Practice 1", session: race.fp1)
                    SessionRow(label: "Free Practice 2", session: race.fp2)
                    SessionRow(label: "Free Practice 3", session: race.fp3)
                    SessionRow(label: "Qualifying", session: race.qualy)
                    if let sprintQualy = race.sprintQualy {
                        SessionRow(label: "Sprint Qualifying", session: sprintQualy)
                    }
                    if let sprintRace = race.sprintRace {
                        SessionRow(label: "Sprint Race", session: sprintRace)
                    }
                    Divider().background(.white.opacity(0.15))
                    SessionRow(label: "\u{1F3C1} Race", session: .init(date: race.date, time: race.time), isRace: true)
                }
                .padding(.top, 4)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            HStack {
                Spacer()
                Text(isExpanded ? "Tap to collapse \u{2191}" : "Tap for session times \u{2193}")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.3))
                Spacer()
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
}

// MARK: - Session Row

/// Single row showing a session label with date and time.
struct SessionRow: View {
    let label: String
    let session: F1Session?
    var isRace: Bool = false

    var body: some View {
        HStack {
            Text(label)
                .font(isRace ? .headline : .caption)
                .fontWeight(isRace ? .bold : .regular)
            Spacer()
            if let date = session?.date {
                Text(formatDate(date))
                    .font(isRace ? .subheadline : .caption)
            }
            if let time = session?.time {
                Text(formatTime(time))
                    .font(isRace ? .subheadline : .caption)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .foregroundStyle(.white.opacity(isRace ? 0.9 : 0.5))
        .padding(.vertical, 2)
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

// MARK: - Previews

#Preview("Next Race - Collapsed") {
    NextRaceCard(race: F1Race(
        raceId: "1",
        round: 7,
        raceName: "British Grand Prix",
        schedule: F1RaceSchedule(
            race: F1Session(date: "2026-07-19", time: "14:00:00Z"),
            qualy: F1Session(date: "2026-07-18", time: "14:00:00Z"),
            fp1: F1Session(date: "2026-07-17", time: "12:30:00Z"),
            fp2: F1Session(date: "2026-07-17", time: "16:00:00Z"),
            fp3: F1Session(date: "2026-07-18", time: "11:00:00Z"),
            sprintQualy: nil,
            sprintRace: nil
        ),
        circuit: F1Circuit(
            circuitId: "silverstone",
            circuitName: "Silverstone Circuit",
            country: "United Kingdom",
            city: "Silverstone",
            circuitLength: nil,
            lapRecord: nil,
            corners: nil,
            firstParticipationYear: nil,
            url: nil
        ),
        url: nil,
        laps: 52,
        winner: nil,
        teamWinner: nil
    ))
    .padding()
    .background(Color(red: 0.08, green: 0.08, blue: 0.12))
    .preferredColorScheme(.dark)
}

#Preview("SessionRow - Race") {
    SessionRow(label: "\u{1F3C1} Race", session: F1Session(date: "2026-07-19", time: "14:00:00Z"), isRace: true)
        .padding()
        .background(Color(red: 0.08, green: 0.08, blue: 0.12))
        .preferredColorScheme(.dark)
}

#Preview("SessionRow - Practice") {
    SessionRow(label: "Free Practice 1", session: F1Session(date: "2026-07-17", time: "12:30:00Z"), isRace: false)
        .padding()
        .background(Color(red: 0.08, green: 0.08, blue: 0.12))
        .preferredColorScheme(.dark)
}

#Preview("SessionRow - No Time") {
    SessionRow(label: "Qualifying", session: F1Session(date: "2026-07-18", time: nil), isRace: false)
        .padding()
        .background(Color(red: 0.08, green: 0.08, blue: 0.12))
        .preferredColorScheme(.dark)
}
