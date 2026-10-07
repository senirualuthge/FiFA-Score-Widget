import SwiftUI

struct F1SessionDetailView: View {
    @State private var documents: [FIADocument] = []
    @State private var driverStandings: [F1DriverStanding] = []
    @State private var constructorStandings: [F1ConstructorStanding] = []
    @State private var eventName: String = ""
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedTab: SessionTab = .results

    enum SessionTab: String, CaseIterable {
        case results = "Results"
        case penalties = "Penalties"
        case championship = "Championship"
    }

    var body: some View {
        ZStack {
            F1Wallpaper()

            Group {
                if isLoading {
                    ProgressView("Loading session data…")
                        .tint(.white)
                } else if let errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                        Text(errorMessage)
                            .multilineTextAlignment(.center)
                        Button("Retry") { Task { await load() } }
                            .buttonStyle(.borderedProminent)
                    }
                    .foregroundStyle(.white.opacity(0.8))
                    .padding()
                } else {
                    VStack(spacing: 0) {
                        // Event header
                        eventHeader
                            .padding(.horizontal)
                            .padding(.top, 8)

                        // Segmented tabs
                        Picker("Section", selection: $selectedTab) {
                            ForEach(SessionTab.allCases, id: \.self) { tab in
                                Text(tab.rawValue).tag(tab)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        .padding(.vertical, 10)

                        // Tab content
                        TabView(selection: $selectedTab) {
                            resultsTab
                                .tag(SessionTab.results)

                            penaltiesTab
                                .tag(SessionTab.penalties)

                            championshipTab
                                .tag(SessionTab.championship)
                        }
                        #if os(iOS)
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        #endif
                    }
                }
            }
        }
        .navigationTitle("Session Detail")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    Task { await load() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(isLoading)
            }
        }
        .task { await load() }
    }

    // MARK: - Event Header

    private var eventHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(sessionDetail?.eventName ?? "Unknown Event")
                    .font(.title2).bold()
                    .foregroundStyle(.white)
                if let count = sessionDetail?.categoryCounts {
                    HStack(spacing: 6) {
                        ForEach(count.prefix(3), id: \.0) { category, num in
                            Label("\(num)", systemImage: "doc.text")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.5))
                            if category != count.prefix(3).last?.0 {
                                Circle()
                                    .fill(.white.opacity(0.2))
                                    .frame(width: 3, height: 3)
                            }
                        }
                    }
                }
            }
            Spacer()
            if let detail = sessionDetail,
               let classification = detail.raceClassification,
               let summary = classification.analysis?.short_summary {
                let winner = extractWinner(from: summary)
                VStack(alignment: .trailing, spacing: 2) {
                    Text("🏆 \(winner)")
                        .font(.headline)
                        .foregroundStyle(.yellow)
                    Text("Race Winner")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.red.opacity(0.1), lineWidth: 1)
                )
        )
    }

    // MARK: - Results Tab

    private var resultsTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let detail = sessionDetail {
                    // Podium section
                    if let classification = detail.raceClassification {
                        RaceResultCard(document: classification)
                    }

                    // Fastest Lap highlight
                    if let classification = detail.raceClassification,
                       let summary = classification.analysis?.short_summary,
                       let fastestLapInfo = extractFastestLap(from: summary) {
                        FastestLapCard(driver: fastestLapInfo.driver, time: fastestLapInfo.time)
                    }

                    // Race details summary
                    if let classification = detail.raceClassification,
                       let summary = classification.analysis?.short_summary {
                        RaceSummaryCard(summary: summary)
                    }

                    // Starting Grid
                    if let grid = detail.startingGrid {
                        StartingGridCard(document: grid)
                    }

                    // Qualifying
                    if let quali = detail.qualifyingClassification {
                        QualifyingCard(document: quali)
                    }
                }

                if sessionDetail == nil {
                    VStack(spacing: 12) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundStyle(.white.opacity(0.3))
                        Text("No race classification data available")
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.5))
                        Text("Documents appear when a race weekend is in progress")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.3))
                    }
                    .frame(maxHeight: .infinity)
                    .padding(.top, 60)
                }
            }
            .padding()
        }
        .refreshable { await load() }
    }

    // MARK: - Penalties Tab

    private var penaltiesTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let detail = sessionDetail {
                    // Summary header
                    let penalties = detail.penaltyDocuments
                    let highPriority = detail.highPriorityPenalties

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(penalties.count) Documents")
                                .font(.title3).bold()
                            Text("\(highPriority.count) high priority")
                                .font(.caption)
                                .foregroundStyle(.red.opacity(0.8))
                        }
                        Spacer()
                        HStack(spacing: 12) {
                            penaltyCountBadge(count: highPriority.count, color: .red, label: "High")
                            penaltyCountBadge(count: penalties.count - highPriority.count, color: .orange, label: "Med/Low")
                        }
                    }
                    .foregroundStyle(.white)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.06))
                    )
                    .padding(.horizontal)

                    if penalties.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "checkmark.shield.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(.green.opacity(0.5))
                            Text("No penalties recorded")
                                .font(.headline)
                                .foregroundStyle(.white.opacity(0.6))
                            Text("This session had a clean race with no infringements")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.3))
                        }
                        .padding(.top, 40)
                    } else {
                        ForEach(penalties) { document in
                            PenaltyCard(document: document)
                                .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.vertical)
        }
        .refreshable { await load() }
    }

    // MARK: - Championship Tab

    private var championshipTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let detail = sessionDetail, let champDoc = detail.championshipDoc {
                    // Championship points from FIA document
                    ChampionshipSummaryCard(document: champDoc)
                        .padding(.horizontal)
                }

                // Driver standings from f1api.dev
                if !driverStandings.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "trophy.fill")
                                .foregroundStyle(.yellow)
                            Text("Drivers Championship")
                                .font(.headline).bold()
                                .foregroundStyle(.white)
                            Spacer()
                            NavigationLink("Full →") {
                                F1StandingsView()
                            }
                            .font(.caption)
                            .foregroundStyle(.red)
                        }

                        VStack(spacing: 6) {
                            ForEach(Array(driverStandings.prefix(8).enumerated()), id: \.element.id) { index, driver in
                                HStack {
                                    Text("\(index + 1)")
                                        .font(.caption).bold()
                                        .foregroundStyle(positionColor(index + 1))
                                        .frame(width: 22)
                                    Text(driver.shortName ?? "")
                                        .font(.subheadline).bold()
                                        .frame(width: 32, alignment: .leading)
                                    Text(driver.driver?.surname ?? "")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.6))
                                    Spacer()
                                    if let wins = driver.wins, wins > 0 {
                                        Text("\(wins)W")
                                            .font(.caption2)
                                            .foregroundStyle(.white.opacity(0.4))
                                            .frame(width: 30, alignment: .trailing)
                                    }
                                    Text("\(driver.points ?? 0)")
                                        .font(.subheadline).bold()
                                        .foregroundStyle(.yellow)
                                        .frame(width: 45, alignment: .trailing)
                                }
                                .padding(.vertical, 3)
                                if index < min(7, driverStandings.count - 1) {
                                    Divider().background(.white.opacity(0.06))
                                }
                            }
                            // Points gap info
                            if driverStandings.count >= 2 {
                                let gap = (driverStandings[0].points ?? 0) - (driverStandings[1].points ?? 0)
                                Text("Leader leads by \(gap) points")
                                    .font(.caption2)
                                    .foregroundStyle(.white.opacity(0.3))
                                    .padding(.top, 4)
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.06))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.yellow.opacity(0.15), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal)
                }

                // Constructor standings
                if !constructorStandings.isEmpty {
                    let sorted = constructorStandings.sorted { ($0.position ?? 99) < ($1.position ?? 99) }
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "building.2.fill")
                                .foregroundStyle(.blue)
                            Text("Constructors Championship")
                                .font(.headline).bold()
                                .foregroundStyle(.white)
                            Spacer()
                        }

                        VStack(spacing: 6) {
                            ForEach(Array(sorted.prefix(5).enumerated()), id: \.element.id) { index, standing in
                                HStack {
                                    Text("\(index + 1)")
                                        .font(.caption).bold()
                                        .foregroundStyle(positionColor(index + 1))
                                        .frame(width: 22)
                                    Text(standing.team?.teamName ?? standing.teamId.capitalized)
                                        .font(.subheadline).bold()
                                        .lineLimit(1)
                                    Spacer()
                                    Text("\(standing.points ?? 0)")
                                        .font(.subheadline).bold()
                                        .foregroundStyle(.yellow)
                                        .frame(width: 45, alignment: .trailing)
                                }
                                .padding(.vertical, 3)
                                if index < min(4, sorted.count - 1) {
                                    Divider().background(.white.opacity(0.06))
                                }
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.06))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.blue.opacity(0.15), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal)
                }

                // Document list
                if let detail = sessionDetail {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("All Session Documents")
                            .font(.headline).bold()
                            .foregroundStyle(.white)
                            .padding(.horizontal)

                        ForEach(detail.categoryCounts, id: \.0) { category, count in
                            HStack {
                                Image(systemName: categoryIcon(for: category))
                                    .foregroundStyle(categoryColor(for: category))
                                Text(category.replacingOccurrences(of: "_", with: " ").capitalized)
                                    .font(.subheadline)
                                Spacer()
                                Text("\(count)")
                                    .font(.subheadline).bold()
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                            .foregroundStyle(.white.opacity(0.7))
                            .padding(.horizontal)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top, 8)
                }
            }
            .padding(.vertical)
        }
        .refreshable { await load() }
    }

    // MARK: - Helpers

    private var sessionDetail: SessionDetail? {
        guard !documents.isEmpty else { return nil }
        return SessionDetail(eventName: eventName, documents: documents)
    }

    private func extractWinner(from summary: String) -> String {
        // "Leclerc won, Russell second and Hamilton third." -> "Leclerc"
        if let won = summary.components(separatedBy: " won").first,
           let lastWord = won.components(separatedBy: " ").last {
            return lastWord
        }
        return "Unknown"
    }

    private func extractFastestLap(from summary: String) -> (driver: String, time: String)? {
        // "Antonelli fastest lap 1:31.777." -> ("Antonelli", "1:31.777")
        guard let range = summary.range(of: "fastest lap") else { return nil }
        let before = summary[summary.startIndex..<range.lowerBound].trimmingCharacters(in: .whitespaces)
        let driver = before.components(separatedBy: " ").last ?? ""

        let after = summary[range.upperBound...]
        let timeStr = after
            .trimmingCharacters(in: .whitespaces)
            .components(separatedBy: CharacterSet.whitespaces).first?
            .trimmingCharacters(in: CharacterSet.punctuationCharacters) ?? ""

        return driver.isEmpty || timeStr.isEmpty ? nil : (driver, timeStr)
    }

    private func positionColor(_ pos: Int) -> Color {
        switch pos {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .white.opacity(0.4)
        }
    }

    private func categoryIcon(for category: String) -> String {
        let c = category.lowercased()
        if c.contains("infring") { return "exclamationmark.shield.fill" }
        if c.contains("decision") { return "gavel.fill" }
        if c.contains("summons") { return "person.fill.questionmark" }
        if c.contains("result") { return "flag.checkered" }
        if c.contains("scrutineer") { return "gearshape.2.fill" }
        if c.contains("event") { return "info.circle.fill" }
        if c.contains("technical") { return "wrench.fill" }
        if c.contains("parc") { return "car.2.fill" }
        return "doc.text.fill"
    }

    private func categoryColor(for category: String) -> Color {
        let c = category.lowercased()
        if c.contains("infring") || c.contains("decision") || c.contains("summons") { return .red }
        if c.contains("result") { return .green }
        if c.contains("scrutineer") || c.contains("technical") { return .blue }
        if c.contains("event") { return .yellow }
        return .white.opacity(0.5)
    }

    private func penaltyCountBadge(count: Int, color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text("\(count) \(label)")
                .font(.caption2)
                .foregroundStyle(color.opacity(0.8))
        }
    }

    @MainActor
    private func load() async {
        isLoading = true
        errorMessage = nil

        do {
        async let docResponse = F1LivePulseService.fetchFIADocumentsResponse()
        async let drivers = F1Service.fetchDriverStandings()
        async let constructors = F1Service.fetchConstructorStandings()

        let (fetchedResponse, fetchedDrivers, fetchedConstructors) = try await (docResponse, drivers, constructors)
        documents = fetchedResponse.documents
        eventName = fetchedResponse.event ?? ""
        driverStandings = fetchedDrivers
        constructorStandings = fetchedConstructors
        } catch {
            errorMessage = "Couldn't load session data: \(error.localizedDescription)"
        }

        isLoading = false
    }
}

// MARK: - Race Result Card

struct RaceResultCard: View {
    let document: FIADocument
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "flag.checkered")
                    .font(.title3)
                    .foregroundStyle(.red)
                Text(document.title ?? "Race Classification")
                    .font(.headline).bold()
                    .foregroundStyle(.white)
                Spacer()
                if let date = document.formattedDate {
                    Text(date)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.4))
                }
            }

            // Summary / Parsed result
            if let summary = document.analysis?.short_summary {
                // Try to extract top 3
                let top3 = extractTop3(from: summary)

                if !top3.isEmpty {
                    // Podium display
                    HStack(spacing: 0) {
                        ForEach(Array(top3.enumerated()), id: \.offset) { index, entry in
                            VStack(spacing: 4) {
                                Text(["🥇", "🥈", "🥉"][index])
                                    .font(.title)
                                Text(entry)
                                    .font(.subheadline).bold()
                                    .foregroundStyle(.white)
                                Text(["1st", "2nd", "3rd"][index])
                                    .font(.caption2)
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                            .frame(maxWidth: .infinity)
                            if index < top3.count - 1 {
                                Divider()
                                    .frame(width: 1, height: 50)
                                    .background(.white.opacity(0.1))
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                // Full summary
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack {
                        Text(isExpanded ? summary : String(summary.prefix(120)) + (summary.count > 120 ? "…" : ""))
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                            .multilineTextAlignment(.leading)
                        Spacer()
                        if summary.count > 120 {
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.3))
                        }
                    }
                }
                .buttonStyle(.plain)
            }

            // Link
            if let url = document.url {
                Link(destination: URL(string: url)!) {
                    HStack {
                        Image(systemName: "doc.text.fill")
                        Text("View Official PDF")
                    }
                    .font(.caption)
                    .foregroundStyle(.red)
                }
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

    private func extractTop3(from summary: String) -> [String] {
        // Parse "Leclerc won, Russell second and Hamilton third." -> ["Leclerc", "Russell", "Hamilton"]
        var result: [String] = []

        // Winner: "X won"
        if let wonRange = summary.range(of: " won") {
            let before = summary[summary.startIndex..<wonRange.lowerBound]
            if let lastWord = before.components(separatedBy: " ").last?.trimmingCharacters(in: .punctuationCharacters), !lastWord.isEmpty {
                result.append(lastWord)
            }
        }

        // Second: "X second"
        if let secondRange = summary.range(of: " second") {
            let before = summary[summary.startIndex..<secondRange.lowerBound]
            if let lastWord = before.components(separatedBy: ",").last?.components(separatedBy: " ").last?.trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: .punctuationCharacters), !lastWord.isEmpty, !result.contains(lastWord) {
                result.append(lastWord)
            }
        }

        // Also try "X and Y third" pattern
        if let thirdRange = summary.range(of: " third") {
            let before = summary[summary.startIndex..<thirdRange.lowerBound]
            let words = before.components(separatedBy: " and ")
            if let secondName = words.last?.components(separatedBy: " ").last?.trimmingCharacters(in: .punctuationCharacters), !secondName.isEmpty {
                // This is actually the third place driver (e.g., "Hamilton third")
                // And the "and" before it is the second place driver
                if result.count == 1 {
                    // Second place is the word before "and"
                    if let andRange = before.range(of: " and ") {
                        let secondPart = before[before.startIndex..<andRange.lowerBound]
                        if let secondWord = secondPart.components(separatedBy: ",").last?.components(separatedBy: " ").last?.trimmingCharacters(in: .punctuationCharacters), !secondWord.isEmpty {
                            result.append(secondWord)
                        }
                    }
                }
                if !result.contains(secondName) {
                    result.append(secondName)
                }
            }
        }

        // Fallback: try comma-separated names before "won"
        if result.isEmpty {
            if let wonRange = summary.range(of: " won") {
                let before = summary[summary.startIndex..<wonRange.lowerBound]
                let names = before.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                result = names
            }
        }

        return Array(result.prefix(3))
    }
}

// MARK: - Fastest Lap Card

struct FastestLapCard: View {
    let driver: String
    let time: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "bolt.fill")
                .font(.title)
                .foregroundStyle(.purple)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text("Fastest Lap")
                    .font(.caption).bold()
                    .foregroundStyle(.purple.opacity(0.8))
                Text(driver)
                    .font(.title3).bold()
                    .foregroundStyle(.white)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("Time")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.4))
                Text(time)
                    .font(.title2).bold()
                    .foregroundStyle(.purple)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.purple.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Race Summary Card

struct RaceSummaryCard: View {
    let summary: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(.blue)
                Text("Race Summary")
                    .font(.headline).bold()
            }
            .foregroundStyle(.white)

            Text(summary)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
                .lineSpacing(4)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.blue.opacity(0.15), lineWidth: 1)
                )
        )
    }
}

// MARK: - Starting Grid Card

struct StartingGridCard: View {
    let document: FIADocument

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "square.grid.3x3.fill")
                    .foregroundStyle(.green)
                Text(document.title ?? "Starting Grid")
                    .font(.headline).bold()
                Spacer()
                if let date = document.formattedDate {
                    Text(date)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
            .foregroundStyle(.white)

            if let summary = document.analysis?.short_summary {
                Text(summary)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }

            if let drivers = document.analysis?.drivers_involved, !drivers.isEmpty {
                HStack(spacing: 4) {
                    Text("Pole:")
                        .font(.caption).bold()
                    Text(drivers.joined(separator: ", "))
                        .font(.caption)
                }
                .foregroundStyle(.white.opacity(0.5))
            }

            if let url = document.url {
                Link(destination: URL(string: url)!) {
                    HStack {
                        Image(systemName: "doc.text.fill")
                        Text("View Grid")
                    }
                    .font(.caption)
                    .foregroundStyle(.green)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.green.opacity(0.15), lineWidth: 1)
                )
        )
    }
}

// MARK: - Qualifying Card

struct QualifyingCard: View {
    let document: FIADocument

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "stopwatch.fill")
                    .foregroundStyle(.orange)
                Text(document.title ?? "Qualifying")
                    .font(.headline).bold()
                Spacer()
                if let date = document.formattedDate {
                    Text(date)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
            .foregroundStyle(.white)

            if let summary = document.analysis?.short_summary {
                Text(summary)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }

            if let url = document.url {
                Link(destination: URL(string: url)!) {
                    HStack {
                        Image(systemName: "doc.text.fill")
                        Text("View Full Qualifying")
                    }
                    .font(.caption)
                    .foregroundStyle(.orange)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.orange.opacity(0.15), lineWidth: 1)
                )
        )
    }
}

// MARK: - Penalty Card (Redesigned with rich data)

struct PenaltyCard: View {
    let document: FIADocument
    @State private var isExpanded = false

    private var details: FIADocumentDetails? { document.analysis?.details }
    private var hasStructuredData: Bool {
        guard let d = details else { return false }
        return d.duration_in_seconds != nil || d.fine_amount != nil
            || d.grid_position_change != nil || d.points != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main card
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            } label: {
                VStack(alignment: .leading, spacing: 10) {
                    // Header row
                    HStack(spacing: 6) {
                        // Category icon pill
                        HStack(spacing: 4) {
                            Image(systemName: document.categoryIcon)
                                .font(.caption2)
                            Text(document.categoryLabel)
                                .font(.caption2).bold()
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(document.categoryColor.opacity(0.2))
                        .foregroundStyle(document.categoryColor)
                        .clipShape(Capsule())

                        // Priority badge
                        if let priority = document.analysis?.priority {
                            Text(priority)
                                .font(.caption2).bold()
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(document.priorityDisplayColor.opacity(0.25))
                                .foregroundStyle(document.priorityDisplayColor)
                                .clipShape(Capsule())
                        }

                        Spacer()

                        if let date = document.formattedDate {
                            Text(date)
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.35))
                        }
                    }

                    // Title
                    HStack(spacing: 8) {
                        if details?.effectiveDecisionType != nil {
                            Image(systemName: details?.penaltyIconName ?? "exclamationmark.shield")
                                .font(.title3)
                                .foregroundStyle(document.priorityDisplayColor)
                        }
                        Text(document.title ?? "Untitled")
                            .font(.subheadline).bold()
                            .foregroundStyle(.white)
                            .lineLimit(isExpanded ? nil : 2)
                    }

                    // Structured penalty description inline
                    if let desc = details?.penaltyDescription {
                        HStack(spacing: 4) {
                            Image(systemName: "info.circle.fill")
                                .font(.caption2)
                            Text(desc)
                                .font(.caption).bold()
                        }
                        .foregroundStyle(.red)
                    }

                    // Summary
                    if let summary = document.analysis?.short_summary {
                        Text(summary)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.65))
                            .lineLimit(isExpanded ? nil : 2)
                    }

                    // Driver chips
                    if let drivers = document.analysis?.drivers_involved, !drivers.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 4) {
                                ForEach(drivers, id: \.self) { number in
                                    Text("#\(number)")
                                        .font(.caption2).bold()
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Color.red.opacity(0.15))
                                        .foregroundStyle(.red)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                }
            }
            .buttonStyle(.plain)

            // Expanded content
            if isExpanded {
                expandedContent
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 10)
            }

            // Indicator
            HStack {
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                    Text(isExpanded ? "Less" : "More")
                        .font(.caption2)
                }
                .foregroundStyle(.white.opacity(0.25))
                .padding(.top, 6)
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(document.priorityDisplayColor)
                            .frame(width: 4)
                            .padding(.vertical, 8)
                    }
                )
        )
    }

    @ViewBuilder
    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Structured penalty data grid
            if hasStructuredData, let d = details {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    if let seconds = d.duration_in_seconds, seconds > 0 {
                        penaltyCell(
                            icon: "clock.badge.exclamationmark",
                            label: "Penalty Duration",
                            value: seconds >= 60 ? "\(seconds / 60)m \(seconds % 60)s" : "\(seconds)s",
                            color: .red
                        )
                    }
                    if let fine = d.fine_amount, fine > 0 {
                        penaltyCell(
                            icon: "dollarsign.circle",
                            label: "Fine",
                            value: "€\(fine)",
                            color: .orange
                        )
                    }
                    if let gridDrop = d.grid_position_change, gridDrop > 0 {
                        penaltyCell(
                            icon: "arrow.down.circle",
                            label: "Grid Drop",
                            value: "\(gridDrop) places",
                            color: .purple
                        )
                    }
                    if let pts = d.points, pts > 0 {
                        penaltyCell(
                            icon: "exclamationmark.circle",
                            label: "License Points",
                            value: "\(pts)",
                            color: .yellow
                        )
                    }
                    if let total = d.total_points_in_last_12_months, total > 0 {
                        penaltyCell(
                            icon: "chart.line.uptrend.xyaxis",
                            label: "12-Month Total",
                            value: "\(total) pts",
                            color: .white
                        )
                    }
                }
                .padding()
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // Decision type
            if let dec = details?.effectiveDecisionType {
                HStack(spacing: 6) {
                    Image(systemName: details?.penaltyIconName ?? "exclamationmark.shield")
                        .font(.caption)
                    Text("Decision:")
                        .font(.caption).bold()
                    Text(dec.replacingOccurrences(of: "_", with: " ").capitalized)
                        .font(.caption)
                }
                .foregroundStyle(.white.opacity(0.6))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            // Reasoning
            if let reasoning = details?.reasoning {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Stewards' Reasoning")
                        .font(.caption).bold()
                        .foregroundStyle(.white.opacity(0.5))
                    Text(reasoning)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.75))
                        .lineSpacing(3)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // All driver chips
            if let drivers = document.analysis?.drivers_involved, !drivers.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Drivers Involved")
                        .font(.caption).bold()
                        .foregroundStyle(.white.opacity(0.5))
                    FlexibleDriverChips(drivers: drivers, isPenalty: true)
                }
            }

            // Official document link
            if let url = document.url {
                Link(destination: URL(string: url)!) {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.text.fill")
                            .font(.caption)
                        Text("View Official PDF")
                            .font(.caption).bold()
                        Image(systemName: "arrow.up.right")
                            .font(.caption2)
                    }
                    .foregroundStyle(.red)
                }
            }
        }
    }

    private func penaltyCell(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
                .frame(width: 16)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.4))
                Text(value)
                    .font(.subheadline).bold()
                    .foregroundStyle(.white)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Championship Summary Card

struct ChampionshipSummaryCard: View {
    let document: FIADocument

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(.yellow)
                Text(document.title ?? "Championship Points")
                    .font(.headline).bold()
                Spacer()
                if let date = document.formattedDate {
                    Text(date)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
            .foregroundStyle(.white)

            if let summary = document.analysis?.short_summary {
                Text(summary)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                    .lineSpacing(4)
            }

            if let url = document.url {
                Link(destination: URL(string: url)!) {
                    HStack {
                        Image(systemName: "doc.text.fill")
                        Text("View Official Document")
                    }
                    .font(.caption)
                    .foregroundStyle(.yellow)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.yellow.opacity(0.15), lineWidth: 1)
                )
        )
    }
}

#Preview {
    NavigationStack {
        F1SessionDetailView()
    }
}
