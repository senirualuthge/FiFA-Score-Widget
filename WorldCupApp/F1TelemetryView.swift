import SwiftUI

struct F1TelemetryView: View {
    @State private var sessions: [F1OpenF1Session] = []
    @State private var selectedSession: F1OpenF1Session?
    @State private var drivers: [F1OpenF1Driver] = []
    @State private var selectedDriver: F1OpenF1Driver?
    @State private var laps: [F1Lap] = []
    @State private var carData: [F1CarData] = []
    @State private var isLoading = true
    @State private var isLoadingDetail = false
    @State private var errorMessage: String?
    @State private var selectedYear: Int = 2025
    @State private var selectedTab: TelemetryTab = .laps

    enum TelemetryTab: String, CaseIterable {
        case laps = "Lap Times"
        case telemetry = "Telemetry"
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
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                        Text(errorMessage)
                            .multilineTextAlignment(.center)
                        Button("Retry") { Task { await loadSessions() } }
                            .buttonStyle(.borderedProminent)
                    }
                    .foregroundStyle(.white.opacity(0.8))
                    .padding()
                } else if selectedSession == nil {
                    sessionPickerView
                } else {
                    sessionDetailView
                }
            }
        }
        .navigationTitle("Telemetry")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                if selectedSession != nil {
                    Button("Back to Sessions") {
                        withAnimation {
                            selectedSession = nil
                            selectedDriver = nil
                            laps = []
                            carData = []
                        }
                    }
                    .font(.caption)
                }
            }
        }
        .task { await loadSessions() }
    }

    // MARK: - Session Picker

    private var sessionPickerView: some View {
        VStack(spacing: 0) {
            // Year picker
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
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(session.country_name ?? "")
                                        .font(.headline).bold()
                                    Spacer()
                                    if let date = session.displayDate {
                                        Text(date)
                                            .font(.caption)
                                            .foregroundStyle(.white.opacity(0.5))
                                    }
                                }
                                if let circuit = session.circuit_short_name {
                                    HStack(spacing: 4) {
                                        Image(systemName: "map.fill")
                                            .font(.caption2)
                                        Text(circuit)
                                            .font(.subheadline)
                                    }
                                    .foregroundStyle(.white.opacity(0.6))
                                }
                            }
                            .foregroundStyle(.white)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
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

    // MARK: - Session Detail

    private var sessionDetailView: some View {
        VStack(spacing: 0) {
            // Session header
            VStack(spacing: 4) {
                Text(selectedSession?.country_name ?? "")
                    .font(.title2).bold()
                if let circuit = selectedSession?.circuit_short_name {
                    Text(circuit)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.black.opacity(0.3))

            // Driver picker
            if !drivers.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(drivers) { driver in
                            Button {
                                selectedDriver = driver
                                Task { await loadTelemetry() }
                            } label: {
                                VStack(spacing: 4) {
                                    ZStack {
                                        Circle()
                                            .fill(selectedDriver?.id == driver.id
                                                  ? Color.red.opacity(0.5)
                                                  : Color.white.opacity(0.1))
                                            .frame(width: 44, height: 44)
                                        Text("\(driver.driver_number ?? 0)")
                                            .font(.caption).bold()
                                    }
                                    Text(driver.name_acronym ?? "")
                                        .font(.caption2).bold()
                                }
                                .foregroundStyle(selectedDriver?.id == driver.id ? .white : .white.opacity(0.6))
                            }
                            .frame(width: 56)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .background(Color.black.opacity(0.2))
            }

            if isLoadingDetail {
                Spacer()
                ProgressView("Loading telemetry…")
                    .tint(.white)
                Spacer()
            } else if selectedDriver != nil {
                // Tab picker
                Picker("View", selection: $selectedTab) {
                    ForEach(TelemetryTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)

                if selectedTab == .laps {
                    lapTimesView
                } else {
                    telemetryView
                }
            } else {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "hand.point.up.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.white.opacity(0.3))
                    Text("Select a driver to view telemetry")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.5))
                }
                Spacer()
            }
        }
    }

    // MARK: - Lap Times View

    private var lapTimesView: some View {
        Group {
            if laps.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.largeTitle)
                        .foregroundStyle(.white.opacity(0.3))
                    Text("No lap data available")
                        .foregroundStyle(.white.opacity(0.5))
                }
                .frame(maxHeight: .infinity)
            } else {
                List {
                    // Best lap highlight
                    if let bestLap = laps.filter({ !($0.is_pit_out_lap ?? false) }).min(by: { ($0.lap_duration ?? 999) < ($1.lap_duration ?? 999) }) {
                        Section {
                            BestLapCard(lap: bestLap, driver: selectedDriver)
                                .listRowInsets(EdgeInsets())
                                .listRowBackground(Color.clear)
                        } header: {
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(.purple)
                                Text("BEST LAP")
                            }
                        }
                    }

                    // All laps
                    Section {
                        ForEach(laps.reversed()) { lap in
                            LapRow(lap: lap, isBest: lap.lap_duration == laps.filter({ !($0.is_pit_out_lap ?? false) }).min(by: { ($0.lap_duration ?? 999) < ($1.lap_duration ?? 999) })?.lap_duration)
                        }
                    } header: {
                        HStack {
                            Text("Lap")
                                .frame(width: 36)
                            Text("Time")
                                .frame(width: 70)
                            Text("S1")
                                .frame(width: 56)
                            Text("S2")
                                .frame(width: 56)
                            Text("S3")
                                .frame(width: 56)
                            Text("Speed")
                        }
                        .font(.caption2).bold()
                        .foregroundStyle(.white.opacity(0.5))
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
    }

    // MARK: - Telemetry View

    private var telemetryView: some View {
        Group {
            if carData.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "chart.xyaxis.line")
                        .font(.largeTitle)
                        .foregroundStyle(.white.opacity(0.3))
                    Text("No car telemetry available")
                        .foregroundStyle(.white.opacity(0.5))
                    Text("Telemetry may not be available for this session")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.3))
                }
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        // Speed telemetry gauge
                        TelemetryGaugeCard(
                            title: "Speed",
                            value: carData.last?.speed ?? 0,
                            unit: "km/h",
                            maxValue: 350,
                            color: .red
                        )

                        // Stats grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            TelemetryStatCard(
                                label: "RPM",
                                value: "\(carData.last?.rpm ?? 0)",
                                icon: "gauge.open.with.lines.needle.33percent",
                                color: .orange
                            )
                            TelemetryStatCard(
                                label: "Gear",
                                value: "\(carData.last?.n_gear ?? 0)",
                                icon: "number",
                                color: .blue
                            )
                            TelemetryStatCard(
                                label: "Throttle",
                                value: "\(carData.last?.throttle ?? 0)%",
                                icon: "arrow.up.to.line",
                                color: .green
                            )
                            TelemetryStatCard(
                                label: "Brake",
                                value: carData.last?.brake == 100 ? "ON" : "OFF",
                                icon: "hand.raised.fill",
                                color: carData.last?.brake == 100 ? .red : .gray
                            )
                            TelemetryStatCard(
                                label: "DRS",
                                value: carData.last?.drsLabel ?? "N/A",
                                icon: "switch.programmable",
                                color: carData.last?.drsLabel == "On" ? .green : .gray
                            )
                        }
                        .padding(.horizontal)

                        // Recent telemetry history
                        if carData.count > 1 {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Recent Data Points")
                                    .font(.headline)
                                    .padding(.horizontal)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(carData.suffix(20)) { point in
                                            VStack(spacing: 4) {
                                                Text("\(point.speed ?? 0, specifier: "%.0f")")
                                                    .font(.caption).bold()
                                                Text("\(point.n_gear ?? 0)")
                                                    .font(.caption2)
                                                    .foregroundStyle(.white.opacity(0.5))
                                            }
                                            .padding(8)
                                            .background(Color.white.opacity(0.06))
                                            .clipShape(RoundedRectangle(cornerRadius: 6))
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
        }
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

        do {
            drivers = try await F1OpenF1Service.fetchDrivers(sessionKey: session.session_key)
        } catch {
            drivers = []
        }
    }

    @MainActor
    private func loadTelemetry() async {
        guard let session = selectedSession, let driver = selectedDriver else { return }

        isLoadingDetail = true

        async let lapData = F1OpenF1Service.fetchLaps(sessionKey: session.session_key, driverNumber: driver.driver_number ?? 0)
        async let carDataResult = F1OpenF1Service.fetchCarData(sessionKey: session.session_key, driverNumber: driver.driver_number ?? 0)

        (laps, carData) = await ((try? lapData) ?? [], (try? carDataResult) ?? [])

        isLoadingDetail = false
    }
}

// MARK: - Best Lap Card

struct BestLapCard: View {
    let lap: F1Lap
    let driver: F1OpenF1Driver?

    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.3))
                    .frame(width: 36, height: 36)
                Text("\(lap.driver_number ?? 0)")
                    .font(.caption).bold()
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(driver?.name_acronym ?? "Driver")
                    .font(.headline)
                Text("Lap \(lap.lap_number ?? 0)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(lap.lapDurationFormatted)
                    .font(.title2).bold()
                    .foregroundStyle(.purple)
                if !(lap.is_pit_out_lap ?? false) {
                    Text("Best lap")
                        .font(.caption2)
                        .foregroundStyle(.purple.opacity(0.7))
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.purple.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.vertical, 4)
    }
}

// MARK: - Lap Row

struct LapRow: View {
    let lap: F1Lap
    let isBest: Bool

    var body: some View {
        HStack {
            Text("\(lap.lap_number ?? 0)")
                .font(.subheadline).bold()
                .foregroundStyle(lap.is_pit_out_lap ?? false ? .blue.opacity(0.7) : .white)
                .frame(width: 36)

            Text(lap.lapDurationFormatted)
                .font(.subheadline).bold()
                .foregroundStyle(isBest ? .purple : .white)
                .frame(width: 70, alignment: .leading)

            Text(lap.sector1Formatted)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
                .frame(width: 56)

            Text(lap.sector2Formatted)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
                .frame(width: 56)

            Text(lap.sector3Formatted)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
                .frame(width: 56)

            if let speed = lap.st_speed {
                Text("\(speed, specifier: "%.0f")")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }

            if lap.is_pit_out_lap ?? false {
                Image(systemName: "wrench.fill")
                    .font(.caption2)
                    .foregroundStyle(.blue)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Telemetry Gauges

struct TelemetryGaugeCard: View {
    let title: String
    let value: Double
    let unit: String
    let maxValue: Double
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white.opacity(0.8))

            ZStack {
                // Gauge background
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 12)
                    .frame(width: 140, height: 140)

                // Gauge fill
                Circle()
                    .trim(from: 0, to: min(value / maxValue, 1.0))
                    .stroke(color, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: value)

                // Center text
                VStack(spacing: 2) {
                    Text("\(value, specifier: "%.0f")")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.white)
                    Text(unit)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }

            // Quick stats
            HStack(spacing: 12) {
                Text("Max: \(maxValue, specifier: "%.0f")")
                    .font(.caption2)
            }
            .foregroundStyle(.white.opacity(0.3))
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }
}

struct TelemetryStatCard: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.title2).bold()
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.15), lineWidth: 1)
                )
        )
    }
}

#Preview {
    NavigationStack {
        F1TelemetryView()
    }
}
