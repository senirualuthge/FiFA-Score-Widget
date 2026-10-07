import Foundation

// MARK: - Sessions

struct F1OpenF1Session: Codable, Identifiable {
    let session_key: Int
    let session_name: String?
    let session_type: String?
    let country_name: String?
    let circuit_short_name: String?
    let date_start: String?
    let date_end: String?
    let year: Int?

    var id: Int { session_key }

    var displayDate: String? {
        guard let date = date_start else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = formatter.date(from: date) {
            let df = DateFormatter()
            df.dateFormat = "MMM d"
            return df.string(from: d)
        }
        formatter.formatOptions = [.withInternetDateTime]
        if let d = formatter.date(from: date) {
            let df = DateFormatter()
            df.dateFormat = "MMM d"
            return df.string(from: d)
        }
        return String(date.prefix(10))
    }

    var displayName: String {
        [country_name, circuit_short_name].compactMap { $0 }.joined(separator: " · ")
    }
}

// MARK: - Lap Data

struct F1Lap: Codable, Identifiable {
    let date_start: String?
    let driver_number: Int?
    let duration_sector_1: Double?
    let duration_sector_2: Double?
    let duration_sector_3: Double?
    let i1_speed: Double?
    let i2_speed: Double?
    let is_pit_out_lap: Bool?
    let lap_duration: Double?
    let lap_number: Int?
    let meeting_key: Int?
    let segments_sector_1: [Int]?
    let segments_sector_2: [Int]?
    let segments_sector_3: [Int]?
    let session_key: Int?
    let st_speed: Double?

    var id: String { "\(session_key ?? 0)-\(driver_number ?? 0)-\(lap_number ?? 0)" }

    var totalSectorTime: Double? {
        guard let s1 = duration_sector_1, let s2 = duration_sector_2, let s3 = duration_sector_3 else { return nil }
        return s1 + s2 + s3
    }

    var sector1Formatted: String { formatSector(duration_sector_1) }
    var sector2Formatted: String { formatSector(duration_sector_2) }
    var sector3Formatted: String { formatSector(duration_sector_3) }
    var lapDurationFormatted: String { formatSector(lap_duration) }

    private func formatSector(_ value: Double?) -> String {
        guard let value else { return "--" }
        return String(format: "%.3f", value)
    }
}

// MARK: - Car Telemetry

struct F1CarData: Codable, Identifiable {
    let brake: Int?
    let date: String?
    let driver_number: Int?
    let drs: Int?
    let meeting_key: Int?
    let n_gear: Int?
    let rpm: Int?
    let session_key: Int?
    let speed: Double?
    let throttle: Int?

    var id: String { "\(date ?? "")-\(driver_number ?? 0)" }

    var drsLabel: String {
        guard let drs else { return "N/A" }
        switch drs {
        case 0, 1: return "Off"
        case 8: return "Detected"
        case 10, 12, 14: return "On"
        default: return "\(drs)"
        }
    }
}

// MARK: - Driver Info (from OpenF1)

struct F1OpenF1Driver: Codable, Identifiable {
    let broadcast_name: String?
    let driver_number: Int?
    let first_name: String?
    let full_name: String?
    let headshot_url: String?
    let name_acronym: String?
    let team_colour: String?
    let team_name: String?

    var id: Int { driver_number ?? 0 }

    var displayName: String { full_name ?? broadcast_name ?? "Driver #\(driver_number ?? 0)" }
    var shortName: String { name_acronym ?? broadcast_name ?? "DRV" }
}
