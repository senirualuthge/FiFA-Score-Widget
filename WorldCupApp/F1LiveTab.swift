import SwiftUI

/// Live tab — shows FIA documents with category breakdown, high-priority penalties,
/// recent document cards, and quick-access navigation.
struct F1LiveTab: View {
    let documents: [FIADocument]
    let docCount: Int

    let refreshAction: () async -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if !documents.isEmpty {
                    documentsContent
                } else {
                    emptyState
                }

                // Quick Access section
                VStack(spacing: 10) {
                    Text("Quick Access")
                        .font(.headline)
                        .foregroundStyle(.white)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        NavPillSmall(title: "Session Detail", icon: "flag.checkered", color: .pink) { F1SessionDetailView() }
                        NavPillSmall(title: "Telemetry", icon: "chart.xyaxis.line", color: .purple) { F1TelemetryView() }
                        NavPillSmall(title: "Compare", icon: "arrow.left.arrow.right", color: .mint) { F1ComparisonView() }
                        NavPillSmall(title: "Standings", icon: "trophy.fill", color: .yellow) { F1StandingsView() }
                    }
                    .padding(.horizontal)
                }
                .padding(.top, 8)

                Spacer()
            }
            .padding(.vertical)
        }
        .refreshable { await refreshAction() }
    }

    // MARK: - Documents Content

    private var documentsContent: some View {
        VStack(spacing: 16) {
            // Summary header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(docCount) Documents")
                        .font(.title3).bold()
                    if let firstDoc = documents.first {
                        HStack(spacing: 4) {
                            Circle().fill(.green).frame(width: 6, height: 6)
                            Text("Last updated \(firstDoc.formattedDate ?? "")")
                                .font(.caption)
                        }
                    }
                }
                Spacer()
                NavigationLink {
                    F1LiveFeedView()
                } label: {
                    HStack(spacing: 4) {
                        Text("All")
                        Image(systemName: "chevron.right")
                    }
                    .font(.caption)
                    .foregroundStyle(.red)
                }
            }
            .foregroundStyle(.white)
            .padding(.horizontal)

            // Category breakdown
            let categories = Dictionary(grouping: documents) { $0.analysis?.document_category?.capitalized ?? "Other" }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(categories.sorted(by: { $0.value.count > $1.value.count }), id: \.key) { category, docs in
                        VStack(spacing: 2) {
                            Text("\(docs.count)")
                                .font(.title2).bold()
                            Text(category.replacingOccurrences(of: "_", with: " "))
                                .font(.caption2)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding(.horizontal)
            }

            // High-priority penalties summary
            let highPenalties = documents.filter { doc in
                guard let p = doc.analysis?.priority?.lowercased() else { return false }
                return (p == "high" || p == "medium") && doc.isPenalty
            }
            if !highPenalties.isEmpty {
                NavigationLink {
                    F1SessionDetailView()
                } label: {
                    HStack {
                        Image(systemName: "exclamationmark.shield.fill")
                            .foregroundStyle(.red)
                        Text("\(highPenalties.count) steward actions")
                            .font(.headline).bold()
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .foregroundStyle(.white)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.red.opacity(0.3), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
            }

            // Recent documents
            ForEach(Array(documents.prefix(5))) { doc in
                NavigationLink {
                    if doc.isRaceClassification || doc.isChampionshipPoints {
                        F1SessionDetailView()
                    } else {
                        F1LiveFeedView()
                    }
                } label: {
                    LiveFeedMiniCard(document: doc)
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
            }

            NavigationLink {
                F1LiveFeedView()
            } label: {
                HStack {
                    Text("View All \(docCount) Documents")
                    Image(systemName: "arrow.right")
                }
                .font(.subheadline).bold()
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .padding(.horizontal)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 48))
                .foregroundStyle(.white.opacity(0.2))
            Text("No live data available")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.5))
            Text("Live documents appear here during race weekends\ntap below to open the full Live Feed")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.3))
                .multilineTextAlignment(.center)
            NavigationLink {
                F1LiveFeedView()
            } label: {
                Text("Open Live Feed")
                    .font(.subheadline).bold()
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.red)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 40)
    }
}

#Preview {
    NavigationStack {
        F1LiveTab(
            documents: [],
            docCount: 0,
            refreshAction: {}
        )
        .preferredColorScheme(.dark)
    }
}
