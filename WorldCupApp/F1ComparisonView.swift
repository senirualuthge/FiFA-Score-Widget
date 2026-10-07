import SwiftUI

struct F1ComparisonView: View {
    @State private var sessions: [F1OpenF1Session] = []
    @State private var drivers: [F1OpenF1Driver] = []
    @State private var selectedSession: F1OpenF1Session?
    @State private var selectedDriver1: F1OpenF1Driver?
    @State private var selectedDriver2: F1OpenF1Driver?
    @State private var laps1: [F1Lap] = []
    @State private var laps2: [F1Lap] = []
    @State private var isLoading = true
    @State private var isLoadingDetail = false
    @State private var errorMessage: String?
    @State private var selectedYear: Int = 2025
    @State private var step: ComparisonStep = .session

    enum ComparisonStep {
        case session, drivers, results
    }

    var body: some View {
        ZStack {
            F1Wallpaper()

            Group {
                if isLoading {
                    ProgressView("Loading sessions…")
                        .tint(.white)
                } else if let errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle").font(.largeTitle)
                        Text(errorMessage).multilineTextAlignment(.center)
                        Button("Retry") { Task { await loadSessions() } }
                            .buttonStyle(.borderedProminent)
                    }
                    .foregroundStyle(.white.opacity(0.8))
                    .padding()
                } else {
                    switch step {
                    case .session: sessionPickerView
                    case .drivers: driverPickerView
                    case .results: comparisonResultsView
                    }
                }
            }
        }
        .navigationTitle("Compare Drivers")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                if step != .session {
                    Button("Back") {
                        withAnimation {
                            switch step {
                            case .drivers:
                                step = .session
                            case .results:
                                step = .drivers
                                selectedDriver2 = nil
                                laps2 = []
                            default: break
                            }
                        }
                    }
                    .font(.caption)
                }
            }
        }
        .task { await loadSessions() }
    }

    // MARK: - Step 1: Session Picker

    private var sessionPickerView: some View {
        VStack(spacing: 0) {
            // Step indicator
            stepIndicator(current: 1, total: 3, label: "Select Session")

            Picker("Year", selection: $selectedYear) {
                Text("2025").tag(2025)
                Text("2024").tag(2024)
                Text("2023").tag(2023)
            }
            .pickerStyle(.segmented)
            .padding()
            .background(Color.black.opacity(0.3))
            .onChange(of: selectedYear) { _, _ in
                Task { await loadSessions() }
            }

            List {
                ForEach(sessions) { session in
                    Button {
                        selectedSession = session
                        Task { await loadDrivers() }
                        withAnimation { step = .drivers }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(session.country_name ?? "")
                                    .font(.headline).bold()
                                if let circuit = session.circuit_short_name {
                                    Text(circuit).font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.6))
                                }
                            }
                            .foregroundStyle(.white)
                            Spacer()
                            if let date = session.displayDate {
                                Text(date).font(.caption)
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                            Image(systemName: "chevron.right").font(.caption)
                                .foregroundStyle(.white.opacity(0.3))
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 4)
                }
            }
            .scrollContentBackground(.hidden)
        }
    }

    // MARK: - Step 2: Driver Picker

    private var driverPickerView: some View {
        VStack(spacing: 0) {
            stepIndicator(current: 2, total: 3, label: "Select Two Drivers")

            if let session = selectedSession {
                VStack(spacing: 2) {
                    Text(session.country_name ?? "").font(.headline)
                    if let circuit = session.circuit_short_name {
                        Text(circuit).font(.caption).foregroundStyle(.white.opacity(0.5))
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.black.opacity(0.3))
            }

            if drivers.isEmpty {
                Spacer()
                ProgressView("Loading drivers…").tint(.white)
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        // Driver 1 selection
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Driver 1")
                                    .font(.headline).bold()
                                    .foregroundStyle(.red)
                                Spacer()
                                if let d1 = selectedDriver1 {
                                    Text(d1.name_acronym ?? "")
                                        .font(.caption).padding(.horizontal, 8).padding(.vertical, 4)
                                        .background(Color.red.opacity(0.3)).clipShape(Capsule())
                                }
                            }
                            .padding(.horizontal)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(drivers) { driver in
                                        Button {
                                            selectedDriver1 = driver
                                        } label: {
                                            VStack(spacing: 4) {
                                                ZStack {
                                                    Circle()
                                                        .fill(selectedDriver1?.id == driver.id ? Color.red : Color.white.opacity(0.1))
                                                        .frame(width: 50, height: 50)
                                                    Text("\(driver.driver_number ?? 0)")
                                                        .font(.caption).bold()
                                                }
                                                Text(driver.name_acronym ?? "")
                                                    .font(.caption2).bold()
                                                Text(driver.team_name ?? "")
                                                    .font(.caption2).foregroundStyle(.white.opacity(0.4))
                                                    .lineLimit(1)
                                            }
                                            .frame(width: 64)
                                            .foregroundStyle(selectedDriver1?.id == driver.id ? .white : .white.opacity(0.6))
                                        }
                                        .disabled(selectedDriver2?.id == driver.id)
                                        .opacity(selectedDriver2?.id == driver.id ? 0.3 : 1)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }

                        Divider().background(.white.opacity(0.1)).padding(.horizontal)

                        // Driver 2 selection
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Driver 2")
                                    .font(.headline).bold()
                                    .foregroundStyle(.blue)
                                Spacer()
                                if let d2 = selectedDriver2 {
                                    Text(d2.name_acronym ?? "")
                                        .font(.caption).padding(.horizontal, 8).padding(.vertical, 4)
                                        .background(Color.blue.opacity(0.3)).clipShape(Capsule())
                                }
                            }
                            .padding(.horizontal)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(drivers) { driver in
                                        Button {
                                            selectedDriver2 = driver
                                        } label: {
                                            VStack(spacing: 4) {
                                                ZStack {
                                                    Circle()
                                                        .fill(selectedDriver2?.id == driver.id ? Color.blue : Color.white.opacity(0.1))
                                                        .frame(width: 50, height: 50)
                                                    Text("\(driver.driver_number ?? 0)")
                                                        .font(.caption).bold()
                                                }
                                                Text(driver.name_acronym ?? "")
                                                    .font(.caption2).bold()
                                                Text(driver.team_name ?? "")
                                                    .font(.caption2).foregroundStyle(.white.opacity(0.4))
                                                    .lineLimit(1)
                                            }
                                            .frame(width: 64)
                                            .foregroundStyle(selectedDriver2?.id == driver.id ? .white : .white.opacity(0.6))
                                        }
                                        .disabled(selectedDriver1?.id == driver.id)
                                        .opacity(selectedDriver1?.id == driver.id ? 0.3 : 1)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                }

                // Compare button
                if selectedDriver1 != nil && selectedDriver2 != nil {
                    Button {
                        Task { await loadComparisonData() }
                        withAnimation { step = .results }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.left.arrow.right")
                            Text("Compare Lap Times")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .padding()
                }
            }
        }
    }

    // MARK: - Step 3: Comparison Results

    private var comparisonResultsView: some View {
        Group {
            if isLoadingDetail {
                Spacer()
                ProgressView("Loading lap data…").tint(.white)
                Spacer()
            } else if laps1.isEmpty && laps2.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle").font(.largeTitle)
                    Text("No lap data available for these drivers").foregroundStyle(.white.opacity(0.5))
                }
                Spacer()
            } else {
                comparisonContent
            }
        }
    }

    private var comparisonContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header with driver info
                HStack(spacing: 12) {
                    driverHeader(driver: selectedDriver1, color: .red, laps: laps1)
                    Text("VS")
                        .font(.title).bold()
                        .foregroundStyle(.white.opacity(0.5))
                    driverHeader(driver: selectedDriver2, color: .blue, laps: laps2)
                }
                .padding(.horizontal)

                // Best lap comparison
                if let best1 = laps1.filter({ !($0.is_pit_out_lap ?? false) }).min(by: { ($0.lap_duration ?? 999) < ($1.lap_duration ?? 999) }),
                   let best2 = laps2.filter({ !($0.is_pit_out_lap ?? false) }).min(by: { ($0.lap_duration ?? 999) < ($1.lap_duration ?? 999) }) {
                    bestLapComparison(best1: best1, best2: best2)
                        .padding(.horizontal)
                }

                // Lap time comparison chart
                lapComparisonChart
                    .padding(.horizontal)

                // Lap time table
                lapComparisonTable
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }

    private func driverHeader(driver: F1OpenF1Driver?, color: Color, laps: [F1Lap]) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.3))
                    .frame(width: 52, height: 52)
                Text("\(driver?.driver_number ?? 0)")
                    .font(.title2).bold()
            }
            Text(driver?.name_acronym ?? "")
                .font(.headline)
            Text(driver?.team_name ?? "")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.5))
                .lineLimit(1)
            HStack(spacing: 4) {
                Text("\(laps.count)")
                    .font(.title3).bold()
                Text("laps")
                    .font(.caption2)
            }
            .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.06))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.3), lineWidth: 1))
        )
    }

    private func bestLapComparison(best1: F1Lap, best2: F1Lap) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "star.fill").foregroundStyle(.yellow)
                Text("Best Lap Comparison").font(.headline).bold()
                Spacer()
            }

            HStack(spacing: 0) {
                // Driver 1 best
                VStack(spacing: 4) {
                    Text("\(selectedDriver1?.name_acronym ?? "")")
                        .font(.caption).bold()
                    Text(best1.lapDurationFormatted)
                        .font(.title2).bold()
                        .foregroundStyle(.purple)
                    Text("Lap \(best1.lap_number ?? 0)")
                        .font(.caption2).foregroundStyle(.white.opacity(0.5))
                    HStack(spacing: 8) {
                        Text("S1 \(best1.sector1Formatted)")
                        Text("S2 \(best1.sector2Formatted)")
                        Text("S3 \(best1.sector3Formatted)")
                    }
                    .font(.caption2).foregroundStyle(.white.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.purple.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                // Difference
                let diff = abs((best1.lap_duration ?? 0) - (best2.lap_duration ?? 0))
                VStack(spacing: 2) {
                    Text("Gap")
                        .font(.caption2).foregroundStyle(.white.opacity(0.5))
                    Text("\(diff, specifier: "%.3f")")
                        .font(.headline).bold()
                        .foregroundStyle(.yellow)
                    Text("seconds")
                        .font(.caption2).foregroundStyle(.white.opacity(0.3))
                    let faster = (best1.lap_duration ?? 999) < (best2.lap_duration ?? 999) ? selectedDriver1?.name_acronym ?? "" : selectedDriver2?.name_acronym ?? ""
                    Text("\(faster) faster")
                        .font(.caption2).bold()
                        .foregroundStyle(.green)
                }
                .padding(.horizontal, 12)

                // Driver 2 best
                VStack(spacing: 4) {
                    Text("\(selectedDriver2?.name_acronym ?? "")")
                        .font(.caption).bold()
                    Text(best2.lapDurationFormatted)
                        .font(.title2).bold()
                        .foregroundStyle(.purple)
                    Text("Lap \(best2.lap_number ?? 0)")
                        .font(.caption2).foregroundStyle(.white.opacity(0.5))
                    HStack(spacing: 8) {
                        Text("S1 \(best2.sector1Formatted)")
                        Text("S2 \(best2.sector2Formatted)")
                        Text("S3 \(best2.sector3Formatted)")
                    }
                    .font(.caption2).foregroundStyle(.white.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.purple.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.06))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.purple.opacity(0.2), lineWidth: 1))
        )
    }

    private var lapComparisonChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill").foregroundStyle(.green)
                Text("Lap Time Comparison").font(.headline).bold()
                Spacer()
            }

            // Find max lap count
            let maxLaps = max(laps1.count, laps2.count)

            ScrollView(.horizontal, showsIndicators: false) {
                VStack(spacing: 4) {
                    // Find min/max for scaling
                    let allLaps = (laps1 + laps2).compactMap { $0.lap_duration }
                    let minTime = allLaps.min() ?? 0
                    let maxTime = allLaps.max() ?? 100
                    let range = max(maxTime - minTime, 1)

                    ForEach(1...maxLaps, id: \.self) { lapNum in
                        let lap1 = laps1.first(where: { $0.lap_number == lapNum })
                        let lap2 = laps2.first(where: { $0.lap_number == lapNum })

                        if lap1 != nil || lap2 != nil {
                            HStack(spacing: 8) {
                                Text("L\(lapNum)")
                                    .font(.system(size: 9)).bold()
                                    .foregroundStyle(.white.opacity(0.4))
                                    .frame(width: 18)

                                // Driver 1 bar
                                if let t1 = lap1?.lap_duration {
                                    let width = ((t1 - minTime) / range) * 100
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.red.opacity(0.7))
                                        .frame(width: max(width * 2, 4), height: 12)
                                } else {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.clear)
                                        .frame(width: 4, height: 12)
                                }

                                Spacer().frame(width: 4)

                                // Driver 2 bar
                                if let t2 = lap2?.lap_duration {
                                    let width = ((t2 - minTime) / range) * 100
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.blue.opacity(0.7))
                                        .frame(width: max(width * 2, 4), height: 12)
                                } else {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.clear)
                                        .frame(width: 4, height: 12)
                                }

                                // Times
                                if let t1 = lap1?.lap_duration {
                                    Text("\(t1, specifier: "%.3f")")
                                        .font(.system(size: 9))
                                        .foregroundStyle(.red.opacity(0.7))
                                        .frame(width: 56, alignment: .trailing)
                                } else {
                                    Text("--").font(.system(size: 9))
                                        .foregroundStyle(.white.opacity(0.2))
                                        .frame(width: 56, alignment: .trailing)
                                }

                                if let t2 = lap2?.lap_duration {
                                    Text("\(t2, specifier: "%.3f")")
                                        .font(.system(size: 9))
                                        .foregroundStyle(.blue.opacity(0.7))
                                        .frame(width: 56, alignment: .trailing)
                                } else {
                                    Text("--").font(.system(size: 9))
                                        .foregroundStyle(.white.opacity(0.2))
                                        .frame(width: 56, alignment: .trailing)
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.06))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.green.opacity(0.2), lineWidth: 1))
        )
    }

    private var lapComparisonTable: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "tablecells").foregroundStyle(.blue)
                Text("All Laps").font(.headline).bold()
                Spacer()
            }

            let allLapNumbers = Set((laps1 + laps2).compactMap { $0.lap_number }).sorted()

            // Header
            HStack {
                Text("Lap").frame(width: 28, alignment: .leading)
                Text(selectedDriver1?.name_acronym ?? "D1").frame(width: 64)
                Text(selectedDriver2?.name_acronym ?? "D2").frame(width: 64)
                Text("Diff").frame(width: 56)
            }
            .font(.caption2).bold()
            .foregroundStyle(.white.opacity(0.5))

            Divider().background(.white.opacity(0.1))

            ForEach(allLapNumbers, id: \.self) { lapNum in
                let lap1 = laps1.first(where: { $0.lap_number == lapNum })
                let lap2 = laps2.first(where: { $0.lap_number == lapNum })
                let diff = abs((lap1?.lap_duration ?? 0) - (lap2?.lap_duration ?? 0))
                let faster = (lap1?.lap_duration ?? 999) < (lap2?.lap_duration ?? 999)

                HStack {
                    Text("\(lapNum)").font(.caption).bold()
                        .foregroundStyle(.white).frame(width: 28, alignment: .leading)

                    Text(lap1?.lapDurationFormatted ?? "--")
                        .font(.caption)
                        .foregroundStyle(lap1 != nil ? .red.opacity(0.8) : .white.opacity(0.2))
                        .frame(width: 64)

                    Text(lap2?.lapDurationFormatted ?? "--")
                        .font(.caption)
                        .foregroundStyle(lap2 != nil ? .blue.opacity(0.8) : .white.opacity(0.2))
                        .frame(width: 64)

                    if lap1 != nil && lap2 != nil {
                        Text("\(diff, specifier: "%.3f")")
                            .font(.caption).bold()
                            .foregroundStyle(faster ? .green : .orange)
                            .frame(width: 56)
                    } else {
                        Text("--").font(.caption)
                            .foregroundStyle(.white.opacity(0.2)).frame(width: 56)
                    }
                }
                .padding(.vertical, 2)

                if lapNum != allLapNumbers.last {
                    Divider().background(.white.opacity(0.04))
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.06))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.blue.opacity(0.2), lineWidth: 1))
        )
    }

    // MARK: - Step Indicator

    private func stepIndicator(current: Int, total: Int, label: String) -> some View {
        HStack(spacing: 8) {
            ForEach(1...total, id: \.self) { i in
                Circle()
                    .fill(i <= current ? Color.red : Color.white.opacity(0.2))
                    .frame(width: 8, height: 8)
            }
            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
                .padding(.leading, 4)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.3))
    }

    // MARK: - Loading

    @MainActor
    private func loadSessions() async {
        isLoading = true
        errorMessage = nil
        do {
            sessions = try await F1OpenF1Service.fetchRaceSessions(year: selectedYear)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    @MainActor
    private func loadDrivers() async {
        guard let session = selectedSession else { return }
        drivers = (try? await F1OpenF1Service.fetchDrivers(sessionKey: session.session_key)) ?? []
    }

    @MainActor
    private func loadComparisonData() async {
        guard let session = selectedSession,
              let d1 = selectedDriver1,
              let d2 = selectedDriver2 else { return }

        isLoadingDetail = true

        async let l1 = F1OpenF1Service.fetchLaps(sessionKey: session.session_key, driverNumber: d1.driver_number ?? 0)
        async let l2 = F1OpenF1Service.fetchLaps(sessionKey: session.session_key, driverNumber: d2.driver_number ?? 0)

        (laps1, laps2) = await ((try? l1) ?? [], (try? l2) ?? [])

        isLoadingDetail = false
    }
}

#Preview {
    NavigationStack {
        F1ComparisonView()
    }
}
