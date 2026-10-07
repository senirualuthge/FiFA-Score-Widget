import SwiftUI

// MARK: - FIA Documents

struct FIADocumentsResponse: Codable {
    let documents: [FIADocument]
    let event: String?
    let meeting_index: Int?
}

struct FIADocument: Codable, Identifiable {
    let analysis: FIADocumentAnalysis?
    let date: String?
    let title: String?
    let url: String?

    var id: String { url ?? title ?? UUID().uuidString }

    var formattedDate: String? {
        guard let date else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = formatter.date(from: date) {
            let df = DateFormatter()
            df.dateFormat = "MMM d '·' HH:mm"
            return df.string(from: d)
        }
        formatter.formatOptions = [.withInternetDateTime]
        if let d = formatter.date(from: date) {
            let df = DateFormatter()
            df.dateFormat = "MMM d '·' HH:mm"
            return df.string(from: d)
        }
        return date
    }

    // MARK: - Document Type Detection

    var isRaceClassification: Bool {
        guard let title = title?.lowercased() else { return false }
        return title.contains("classification") && !title.contains("qualifying")
    }

    var isQualifyingClassification: Bool {
        guard let title = title?.lowercased() else { return false }
        return title.contains("qualifying") && title.contains("classification")
    }

    var isStartingGrid: Bool {
        guard let title = title?.lowercased() else { return false }
        return title.contains("starting grid") || title.contains("provisional starting grid") || title.contains("final starting grid")
    }

    var isChampionshipPoints: Bool {
        guard let title = title?.lowercased() else { return false }
        return (title.contains("championship") && title.contains("points")) ||
               (analysis?.document_category?.lowercased() == "results" && title.contains("championship"))
    }

    var isPenalty: Bool {
        guard let cat = analysis?.document_category?.lowercased() else { return false }
        return cat == "infringement" || cat == "decision" || cat == "summons"
    }

    var penaltyType: String? {
        analysis?.details?.effectiveDecisionType
    }

    var isTechnical: Bool {
        guard let cat = analysis?.document_category?.lowercased() else { return false }
        return cat == "technical_allocations" || cat == "parc_ferme_changes" || cat == "scrutineering"
    }

    var isEventInfo: Bool {
        guard let cat = analysis?.document_category?.lowercased() else { return false }
        return cat == "event_info"
    }

    var driverNumbers: [String] {
        analysis?.drivers_involved ?? []
    }

    // MARK: - Display Properties

    /// SF Symbol icon for the document category.
    var categoryIcon: String {
        guard let cat = analysis?.document_category?.lowercased() else { return "doc.text.fill" }
        switch cat {
        case "results": return "flag.checkered"
        case "decision": return "gavel.fill"
        case "infringement": return "exclamationmark.shield.fill"
        case "summons": return "person.fill.questionmark"
        case "scrutineering": return "gearshape.2.fill"
        case "event_info": return "info.circle.fill"
        case "technical_allocations": return "wrench.fill"
        case "parc_ferme_changes": return "car.2.fill"
        default: return "doc.text.fill"
        }
    }

    /// Color associated with the document category.
    var categoryColor: Color {
        guard let cat = analysis?.document_category?.lowercased() else { return .white.opacity(0.5) }
        switch cat {
        case "results": return .green
        case "decision", "infringement", "summons": return .red
        case "scrutineering", "technical_allocations", "parc_ferme_changes": return .blue
        case "event_info": return .yellow
        default: return .white.opacity(0.5)
        }
    }

    /// Human-readable label for the document category.
    var categoryLabel: String {
        guard let cat = analysis?.document_category else { return "Document" }
        return cat.replacingOccurrences(of: "_", with: " ").capitalized
    }

    /// Priority color for badges and borders.
    var priorityDisplayColor: Color {
        guard let priority = analysis?.priority?.lowercased() else { return .gray.opacity(0.3) }
        switch priority {
        case "high": return .red
        case "medium": return .orange
        case "low": return .yellow
        default: return .gray.opacity(0.3)
        }
    }
}

// MARK: - Analysis & Details

struct FIADocumentAnalysis: Codable {
    let _version: Int?
    let details: FIADocumentDetails?
    let document_category: String?
    let drivers_involved: [String]?
    let priority: String?
    let short_summary: String?
}

struct FIADocumentDetails: Codable {
    let reasoning: String?
    let decision_type: String?
    let type: String?
    let duration_in_seconds: Int?
    let fine_amount: Int?
    let grid_position_change: Int?
    let points: Int?
    let total_points_in_last_12_months: Int?

    /// Best available penalty type key.
    var effectiveDecisionType: String? {
        decision_type ?? type
    }

    /// Human-readable penalty magnitude summary.
    var penaltyDescription: String? {
        var parts: [String] = []
        if let seconds = duration_in_seconds, seconds > 0 {
            if seconds >= 60 {
                let mins = seconds / 60
                let secs = seconds % 60
                parts.append("\(mins)m\(secs)s penalty")
            } else {
                parts.append("\(seconds)s penalty")
            }
        }
        if let fine = fine_amount, fine > 0 {
            parts.append("€\(fine) fine")
        }
        if let gridDrop = grid_position_change, gridDrop > 0 {
            parts.append("\(gridDrop)-place grid drop")
        }
        if let pts = points, pts > 0 {
            parts.append("\(pts) license point(s)")
        }
        return parts.isEmpty ? nil : parts.joined(separator: " + ")
    }

    /// SF Symbol for the penalty type.
    var penaltyIconName: String {
        let t = effectiveDecisionType?.lowercased() ?? ""
        if t.contains("time") || (duration_in_seconds ?? 0) > 0 { return "clock.badge.exclamationmark" }
        if t.contains("grid") || (grid_position_change ?? 0) > 0 { return "arrow.down.circle" }
        if t.contains("fine") || (fine_amount ?? 0) > 0 { return "dollarsign.circle" }
        if t.contains("reprimand") || t.contains("warning") { return "exclamationmark.bubble" }
        if t.contains("no further") || t.contains("no_further") { return "hand.thumbsup" }
        if t.contains("summons") || t.contains("summon") { return "person.fill.questionmark" }
        if t.contains("other") { return "questionmark.circle" }
        return "exclamationmark.shield"
    }
}

// MARK: - Driver List

struct F1LivePulseDriver: Codable, Identifiable {
    let RacingNumber: String?
    let TeamName: String?
    let Tla: String?
    let BroadcastName: String?
    let FullName: String?

    var id: String { RacingNumber ?? FullName ?? UUID().uuidString }
}

// MARK: - Session Detail Aggregator

struct SessionDetail {
    let eventName: String
    let documents: [FIADocument]

    var raceClassification: FIADocument? {
        let classifications = documents.filter { $0.isRaceClassification }
        return classifications.first(where: { $0.title?.lowercased().contains("final") ?? false })
            ?? classifications.last
    }

    var qualifyingClassification: FIADocument? {
        documents.first(where: { $0.isQualifyingClassification })
    }

    var startingGrid: FIADocument? {
        documents.first(where: { $0.isStartingGrid })
    }

    var championshipDoc: FIADocument? {
        documents.first(where: { $0.isChampionshipPoints })
    }

    var penaltyDocuments: [FIADocument] {
        documents.filter { $0.isPenalty }
            .sorted { ($0.date ?? "") > ($1.date ?? "") }
    }

    var highPriorityPenalties: [FIADocument] {
        penaltyDocuments.filter { $0.analysis?.priority?.lowercased() == "high" }
    }

    var categoryCounts: [(String, Int)] {
        let categories = Dictionary(grouping: documents) { doc in
            doc.analysis?.document_category?.capitalized ?? "Other"
        }
        return categories.map { ($0.key, $0.value.count) }.sorted { $0.1 > $1.1 }
    }
}
