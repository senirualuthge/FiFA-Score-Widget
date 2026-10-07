import SwiftUI

/// A compact card displaying an FIA document summary with category icon,
/// title, short summary, priority badge, and timestamp.
/// Used in the overview, live, and full live feed views.
struct LiveFeedMiniCard: View {
    let document: FIADocument
    @AppStorage("F1.showDocBadges") private var showDocBadges = true

    var body: some View {
        HStack(spacing: 10) {
            // Category icon
            Image(systemName: document.categoryIcon)
                .font(.title3)
                .foregroundStyle(document.categoryColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(document.title ?? "")
                    .font(.caption).bold()
                    .foregroundStyle(.white)
                    .lineLimit(1)
                if let summary = document.analysis?.short_summary {
                    Text(summary)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                        .lineLimit(1)
                }
            }

            Spacer()

            // Priority dot + time
            VStack(alignment: .trailing, spacing: 2) {
                if showDocBadges, let priority = document.analysis?.priority {
                    Text(priority)
                        .font(.system(size: 8)).bold()
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(document.priorityDisplayColor.opacity(0.3))
                        .foregroundStyle(document.priorityDisplayColor)
                        .clipShape(Capsule())
                }
                if let date = document.formattedDate {
                    Text(date)
                        .font(.system(size: 8))
                        .foregroundStyle(.white.opacity(0.3))
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(document.categoryColor.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

#Preview("Results - Low Priority") {
    LiveFeedMiniCard(document: FIADocument(
        analysis: FIADocumentAnalysis(
            _version: 1, details: nil,
            document_category: "Results", drivers_involved: nil,
            priority: "low", short_summary: "Final race classification with driver positions"
        ),
        date: "2026-07-11T15:00:00Z",
        title: "Race Classification",
        url: nil
    ))
    .padding()
    .background(Color(red: 0.08, green: 0.08, blue: 0.12))
    .preferredColorScheme(.dark)
}

#Preview("Penalty - High Priority") {
    LiveFeedMiniCard(document: FIADocument(
        analysis: FIADocumentAnalysis(
            _version: 1,
            details: FIADocumentDetails(
                reasoning: "Caused collision at Turn 1",
                decision_type: "Time Penalty", type: nil,
                duration_in_seconds: 10, fine_amount: nil,
                grid_position_change: nil, points: 2,
                total_points_in_last_12_months: nil
            ),
            document_category: "Decision", drivers_involved: ["16", "1"],
            priority: "high", short_summary: "10s time penalty for causing a collision"
        ),
        date: "2026-07-11T14:30:00Z",
        title: "Stewards Decision Document 47",
        url: nil
    ))
    .padding()
    .background(Color(red: 0.08, green: 0.08, blue: 0.12))
    .preferredColorScheme(.dark)
}

#Preview("Event Info - Low") {
    LiveFeedMiniCard(document: FIADocument(
        analysis: FIADocumentAnalysis(
            _version: 1, details: nil,
            document_category: "event_info", drivers_involved: nil,
            priority: "low", short_summary: "Updated schedule for Sunday race day"
        ),
        date: "2026-07-10T09:00:00Z",
        title: "Event Info",
        url: nil
    ))
    .padding()
    .background(Color(red: 0.08, green: 0.08, blue: 0.12))
    .preferredColorScheme(.dark)
}

#Preview("List") {
    VStack(spacing: 8) {
        LiveFeedMiniCard(document: FIADocument(
            analysis: FIADocumentAnalysis(_version: 1, details: nil, document_category: "Results", drivers_involved: nil, priority: "low", short_summary: "Final classification"),
            date: "2026-07-11T15:00:00Z", title: "Race Classification", url: nil
        ))
        LiveFeedMiniCard(document: FIADocument(
            analysis: FIADocumentAnalysis(_version: 1,
                details: FIADocumentDetails(reasoning: "", decision_type: "Time Penalty", type: nil, duration_in_seconds: 5, fine_amount: nil, grid_position_change: nil, points: nil, total_points_in_last_12_months: nil),
                document_category: "Decision", drivers_involved: nil, priority: "medium", short_summary: "5s penalty for track limits"),
            date: "2026-07-11T13:45:00Z", title: "Stewards Decision", url: nil
        ))
    }
    .padding()
    .background(Color(red: 0.08, green: 0.08, blue: 0.12))
    .preferredColorScheme(.dark)
}
