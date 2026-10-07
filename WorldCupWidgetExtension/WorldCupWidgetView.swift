import SwiftUI
import WidgetKit
import AppIntents

// MARK: - Root widget view

struct WorldCupWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: WorldCupEntry

    /// Resolved current page (clamped to valid range)
    private var currentPage: WidgetPage {
        WidgetPage(rawValue: entry.configuration.displayPage) ?? .worldCup
    }

    var body: some View {
        ZStack {
            // Decorative watermark
            GeometryReader { geo in
                Image(systemName: pageWatermark)
                    .resizable()
                    .scaledToFit()
                    .frame(width: geo.size.width * 0.55)
                    .foregroundStyle(.white.opacity(0.06))
                    .position(x: geo.size.width * 0.85, y: geo.size.height * 0.85)
            }

            // Content layer
            pageContent

            // Tappable left / right zones — invisible but full-height
            GeometryReader { geo in
                HStack(spacing: 0) {
                    // Left zone → previous page
                    Button(intent: makePrevIntent()) {
                        Color.clear
                    }
                    .buttonStyle(.plain)
                    .frame(width: geo.size.width * 0.25, height: geo.size.height)

                    Spacer()

                    // Right zone → next page
                    Button(intent: makeNextIntent()) {
                        Color.clear
                    }
                    .buttonStyle(.plain)
                    .frame(width: geo.size.width * 0.25, height: geo.size.height)
                }
            }
        }
    }

    // MARK: - Page content switcher

    @ViewBuilder
    private var pageContent: some View {
        switch currentPage {
        case .worldCup:
            switch family {
            case .systemSmall:
                SmallView(snapshot: entry.snapshot, favorite: entry.configuration.favoriteTeam,
                          page: currentPage)
            case .systemMedium:
                MediumView(snapshot: entry.snapshot, favorite: entry.configuration.favoriteTeam,
                           page: currentPage)
            default:
                LargeView(snapshot: entry.snapshot, favorite: entry.configuration.favoriteTeam,
                          page: currentPage)
            }
        case .f1NextRace:
            F1NextRaceView(f1: entry.f1Snapshot, family: family, page: currentPage)
        case .f1Drivers:
            F1DriversView(f1: entry.f1Snapshot, family: family, page: currentPage)
        case .f1Constructors:
            F1ConstructorsView(f1: entry.f1Snapshot, family: family, page: currentPage)
        }
    }

    // MARK: - Watermark icon per page

    private var pageWatermark: String {
        switch currentPage {
        case .worldCup:        return "soccerball"
        case .f1NextRace:      return "flag.checkered"
        case .f1Drivers:       return "person.fill"
        case .f1Constructors:  return "building.2.fill"
        }
    }

    // MARK: - Intent factories (page numbers baked in at render time)

    private func makeNextIntent() -> NextPageIntent {
        NextPageIntent(nextPage: currentPage.next().rawValue)
    }

    private func makePrevIntent() -> PrevPageIntent {
        PrevPageIntent(prevPage: currentPage.prev().rawValue)
    }
}

// MARK: - Page indicator dots

private struct PageDots: View {
    let current: WidgetPage

    var body: some View {
        HStack(spacing: 4) {
            ForEach(WidgetPage.allCases, id: \.rawValue) { page in
                Circle()
                    .fill(page == current ? Color.white : Color.white.opacity(0.3))
                    .frame(width: page == current ? 5 : 3, height: page == current ? 5 : 3)
            }
        }
    }
}

// MARK: - Page header badge

private struct PageHeader: View {
    let page: WidgetPage
    var body: some View {
        HStack {
            Text(page.title)
                .font(.caption2).bold()
                .foregroundStyle(.secondary)
            Spacer()
            PageDots(current: page)
        }
    }
}

// MARK: - Helpers (shared football helpers)

private func relevantMatch(_ snapshot: WorldCupSnapshot, favorite: TeamEntity?) -> Match? {
    if let favorite {
        let all = snapshot.liveMatches + snapshot.upcomingMatches + snapshot.recentMatches
        if let match = all.first(where: {
            $0.homeTeam.displayName == favorite.name || $0.awayTeam.displayName == favorite.name
        }) { return match }
    }
    return snapshot.liveMatches.first ?? snapshot.upcomingMatches.first ?? snapshot.recentMatches.first
}

private func prioritized(_ matches: [Match], favorite: TeamEntity?) -> [Match] {
    guard let favorite else { return matches }
    return matches.sorted { a, b in
        let aF = a.homeTeam.displayName == favorite.name || a.awayTeam.displayName == favorite.name
        let bF = b.homeTeam.displayName == favorite.name || b.awayTeam.displayName == favorite.name
        if aF == bF { return false }
        return aF && !bF
    }
}

private func relevantStandings(from snapshot: WorldCupSnapshot, favorite: TeamEntity?) -> [StandingRow] {
    let all = snapshot.topStandings
    if let favorite,
       let favRow = all.first(where: { $0.team.displayName == favorite.name }),
       let group = favRow.groupName {
        return all.filter { $0.groupName == group }
    }
    if let first = all.first?.groupName {
        return all.filter { $0.groupName == first }
    }
    return []
}

// MARK: - ⚽ Small World Cup

private struct SmallView: View {
    let snapshot: WorldCupSnapshot
    let favorite: TeamEntity?
    let page: WidgetPage

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            PageHeader(page: page)

            Spacer(minLength: 0)

            if let match = relevantMatch(snapshot, favorite: favorite) {
                Text(match.homeTeam.displayName)
                    .font(.subheadline).bold()
                    .lineLimit(1).minimumScaleFactor(0.5)
                Text(match.displayScore)
                    .font(.title2).bold()
                Text(match.awayTeam.displayName)
                    .font(.subheadline).bold()
                    .lineLimit(1).minimumScaleFactor(0.5)
                if !match.isLive, let meta = match.shortMetaLabel {
                    Text(meta)
                        .font(.caption2).foregroundStyle(.secondary)
                        .lineLimit(1).minimumScaleFactor(0.5)
                }
                Spacer(minLength: 0)
                if match.isLive {
                    Label("LIVE", systemImage: "circle.fill")
                        .font(.caption2).bold().foregroundStyle(.red)
                }
            } else {
                Text("No matches").font(.caption).foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }
        }
        .padding(16)
    }
}

// MARK: - ⚽ Medium World Cup

private struct MediumView: View {
    let snapshot: WorldCupSnapshot
    let favorite: TeamEntity?
    let page: WidgetPage

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 3) {
                PageHeader(page: page)

                let live     = prioritized(snapshot.liveMatches,     favorite: favorite)
                let recent   = prioritized(snapshot.recentMatches,   favorite: favorite)
                let upcoming = prioritized(snapshot.upcomingMatches, favorite: favorite)

                ForEach(live.prefix(1))   { m in MatchRow(match: m, isFavorite: isFav(m)) }
                ForEach(recent.prefix(2)) { m in MatchRow(match: m, showMeta: true, isFavorite: isFav(m)) }
                ForEach(upcoming.prefix(max(0, 2 - recent.count))) { m in
                    MatchRow(match: m, showMeta: true, isFavorite: isFav(m))
                }
                if live.isEmpty && recent.isEmpty && upcoming.isEmpty {
                    Text("No matches").font(.caption2).foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)

            Divider()

            VStack(alignment: .leading, spacing: 3) {
                let rows  = relevantStandings(from: snapshot, favorite: favorite)
                let label = rows.first?.groupName ?? "Standings"
                Text(label).font(.caption).bold().foregroundStyle(.secondary)

                ForEach(rows.prefix(3)) { row in
                    HStack(spacing: 2) {
                        Text(row.team.displayName)
                            .font(.caption2)
                            .bold(favorite != nil && row.team.displayName == favorite?.name)
                            .lineLimit(1).minimumScaleFactor(0.5)
                        Spacer(minLength: 0)
                        Text("\(row.points)p")
                            .font(.caption2).bold().fixedSize()
                    }
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(16)
    }

    private func isFav(_ m: Match) -> Bool {
        guard let f = favorite else { return false }
        return m.homeTeam.displayName == f.name || m.awayTeam.displayName == f.name
    }
}

// MARK: - ⚽ Large World Cup

private struct LargeView: View {
    let snapshot: WorldCupSnapshot
    let favorite: TeamEntity?
    let page: WidgetPage

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            PageHeader(page: page)

            VStack(alignment: .leading, spacing: 3) {
                Text("Live / Upcoming")
                    .font(.caption).bold().foregroundStyle(.secondary)
                let liveUpcoming = prioritized(
                    snapshot.liveMatches + snapshot.upcomingMatches, favorite: favorite)
                ForEach(liveUpcoming.prefix(3)) { m in
                    MatchRow(match: m, showMeta: !m.isLive, isFavorite: isFav(m))
                }
                if liveUpcoming.isEmpty {
                    Text("No upcoming matches").font(.caption2).foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Recent Results")
                    .font(.caption).bold().foregroundStyle(.secondary)
                let recent = prioritized(snapshot.recentMatches, favorite: favorite)
                ForEach(recent.prefix(2)) { m in
                    MatchRow(match: m, showMeta: true, isFavorite: isFav(m))
                }
                if recent.isEmpty {
                    Text("No recent results").font(.caption2).foregroundStyle(.secondary)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 3) {
                let rows  = relevantStandings(from: snapshot, favorite: favorite)
                let label = rows.first?.groupName ?? "Standings"
                Text(label).font(.caption).bold().foregroundStyle(.secondary)

                ForEach(rows.prefix(5)) { row in
                    HStack(spacing: 4) {
                        Text("\(row.position).").font(.caption2).foregroundStyle(.secondary).fixedSize()
                        Text(row.team.displayName)
                            .font(.caption)
                            .bold(favorite != nil && row.team.displayName == favorite?.name)
                            .lineLimit(1).minimumScaleFactor(0.5)
                        Spacer(minLength: 0)
                        Text("\(row.won)-\(row.draw)-\(row.lost)")
                            .font(.caption2).foregroundStyle(.secondary).fixedSize()
                        Text("\(row.points)p").font(.caption).bold().fixedSize()
                    }
                }
            }

            Spacer(minLength: 0)
            Text("Updated \(shortTime(snapshot.lastUpdated))")
                .font(.caption2).foregroundStyle(.secondary)
        }
        .padding(16)
    }

    private func isFav(_ m: Match) -> Bool {
        guard let f = favorite else { return false }
        return m.homeTeam.displayName == f.name || m.awayTeam.displayName == f.name
    }

    private func shortTime(_ date: Date) -> String {
        let f = DateFormatter(); f.timeStyle = .short
        return f.string(from: date)
    }
}

// MARK: - 🏎️ F1 Next Race

private struct F1NextRaceView: View {
    let f1: F1WidgetSnapshot
    let family: WidgetFamily
    let page: WidgetPage

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            PageHeader(page: page)

            if let race = f1.nextRace {
                Text(race.raceName ?? "Next Race")
                    .font(family == .systemSmall ? .subheadline : .headline).bold()
                    .lineLimit(2).minimumScaleFactor(0.7)

                if let circuit = race.circuit {
                    Label(
                        [circuit.city, circuit.country].compactMap { $0 }.joined(separator: ", "),
                        systemImage: "mappin.circle"
                    )
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                }

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    if let days = race.daysUntil, days >= 0 {
                        Text("\(days)")
                            .font(.system(size: family == .systemSmall ? 36 : 48, weight: .black, design: .rounded))
                            .foregroundStyle(.red)
                        Text("days away")
                            .font(.caption).bold()
                            .foregroundStyle(.secondary)
                    } else if let ds = race.raceDateString {
                        Text(ds)
                            .font(.system(size: family == .systemSmall ? 24 : 32, weight: .black))
                            .foregroundStyle(.red)
                    }
                }

                if family != .systemSmall, let last = f1.lastRace {
                    Divider()
                    Text("Last Race")
                        .font(.caption).bold().foregroundStyle(.secondary)
                    Text(last.raceName ?? "—")
                        .font(.caption2).lineLimit(1)
                }
            } else {
                Text("No upcoming race data")
                    .font(.caption).foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
    }
}

// MARK: - 🏎️ F1 Driver Standings

private struct F1DriversView: View {
    let f1: F1WidgetSnapshot
    let family: WidgetFamily
    let page: WidgetPage

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            PageHeader(page: page)

            if f1.driverStandings.isEmpty {
                Text("No standings data").font(.caption).foregroundStyle(.secondary)
            } else {
                ForEach(Array(f1.driverStandings.prefix(family == .systemSmall ? 3 : 5).enumerated()), id: \.offset) { index, driver in
                    HStack(spacing: 4) {
                        Text("\(index + 1)")
                            .font(.caption2).bold()
                            .foregroundStyle(positionColor(index + 1))
                            .frame(width: 14)
                        Text(driver.displayName)
                            .font(.caption2).bold()
                            .lineLimit(1)
                        Spacer(minLength: 0)
                        if family != .systemSmall, let team = driver.teamId {
                            Text(team.capitalized)
                                .font(.system(size: 8))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        Text("\(driver.points ?? 0)pt")
                            .font(.caption2).bold()
                            .foregroundStyle(.yellow)
                    }
                    if index < min(4, f1.driverStandings.count - 1) {
                        Divider().opacity(0.3)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(16)
    }

    private func positionColor(_ pos: Int) -> Color {
        switch pos {
        case 1: return .yellow
        case 2: return Color(white: 0.75)
        case 3: return .orange
        default: return .secondary
        }
    }
}

// MARK: - 🏎️ F1 Constructor Standings

private struct F1ConstructorsView: View {
    let f1: F1WidgetSnapshot
    let family: WidgetFamily
    let page: WidgetPage

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            PageHeader(page: page)

            if f1.constructorStandings.isEmpty {
                Text("No standings data").font(.caption).foregroundStyle(.secondary)
            } else {
                let sorted = f1.constructorStandings.sorted { ($0.position ?? 99) < ($1.position ?? 99) }
                ForEach(Array(sorted.prefix(family == .systemSmall ? 3 : 5).enumerated()), id: \.offset) { index, ctor in
                    HStack(spacing: 4) {
                        Text("\(index + 1)")
                            .font(.caption2).bold()
                            .foregroundStyle(positionColor(index + 1))
                            .frame(width: 14)
                        Text(ctor.team?.teamName ?? ctor.teamId.capitalized)
                            .font(.caption2).bold()
                            .lineLimit(1)
                        Spacer(minLength: 0)
                        Text("\(ctor.points ?? 0)pt")
                            .font(.caption2).bold()
                            .foregroundStyle(.yellow)
                    }
                    if index < min(4, sorted.count - 1) {
                        Divider().opacity(0.3)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(16)
    }

    private func positionColor(_ pos: Int) -> Color {
        switch pos {
        case 1: return .yellow
        case 2: return Color(white: 0.75)
        case 3: return .orange
        default: return .secondary
        }
    }
}

// MARK: - Shared MatchRow

private struct MatchRow: View {
    let match: Match
    var showMeta: Bool = false
    var isFavorite: Bool = false

    var body: some View {
        VStack(alignment: .center, spacing: 1) {
            HStack(spacing: 4) {
                Text(match.homeTeam.displayName)
                    .font(.caption2).bold(isFavorite)
                    .lineLimit(1).minimumScaleFactor(0.5)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                Text(match.displayScore)
                    .font(.caption).bold()
                    .foregroundStyle(match.isLive ? .red : .primary)
                    .fixedSize()
                Text(match.awayTeam.displayName)
                    .font(.caption2).bold(isFavorite)
                    .lineLimit(1).minimumScaleFactor(0.5)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            if showMeta, let meta = match.shortMetaLabel {
                if match.isFinished {
                    // Past match date — small & faded
                    Text(meta)
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary.opacity(0.65))
                        .lineLimit(1).minimumScaleFactor(0.5)
                        .truncationMode(.tail)
                        .frame(maxWidth: .infinity, alignment: .center)
                } else if !match.isLive {
                    // Upcoming — larger & bright
                    Text(meta)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1).minimumScaleFactor(0.5)
                        .truncationMode(.tail)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
    }
}