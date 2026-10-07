import SwiftUI

struct F1LiveFeedView: View {
    @State private var documents: [FIADocument] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedFilter: DocumentFilter = .all

    enum DocumentFilter: String, CaseIterable {
        case all = "All"
        case decisions = "Decisions"
        case penalties = "Penalties"
        case grid = "Grid"
    }

    var body: some View {
        ZStack {
            F1Wallpaper()

            Group {
                if isLoading {
                    ProgressView("Loading live feed\u{2026}")
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
                        // Header
                        HStack {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(.red)
                                    .frame(width: 8, height: 8)
                                    .opacity(isLoading ? 0.5 : 1.0)
                                Text("LIVE")
                                    .font(.caption).bold()
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.red.opacity(0.2))
                            .clipShape(Capsule())

                            Spacer()

                            NavigationLink {
                                F1SessionDetailView()
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "flag.checkered")
                                        .font(.caption2)
                                    Text("Race Hub")
                                        .font(.caption2).bold()
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)

                            Text("\\(documents.count) docs")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.4))
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)

                        // Filter picker
                        Picker("Filter", selection: $selectedFilter) {
                            ForEach(DocumentFilter.allCases, id: \.self) { filter in
                                Text(filter.rawValue).tag(filter)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        .padding(.vertical, 8)

                        if filteredDocuments.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "doc.text.magnifyingglass")
                                    .font(.system(size: 40))
                                    .foregroundStyle(.white.opacity(0.3))
                                Text("No documents available")
                                    .font(.headline)
                                    .foregroundStyle(.white.opacity(0.5))
                                Text("Documents appear here during race weekends")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.3))
                            }
                            .frame(maxHeight: .infinity)
                            .padding()
                        } else {
                            List {
                                ForEach(filteredDocuments) { document in
                                    DocumentRow(document: document)
                                }
                            }
                            .scrollContentBackground(.hidden)
                            .refreshable {
                                await load()
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Live Feed")
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

    private var filteredDocuments: [FIADocument] {
        switch selectedFilter {
        case .all:
            return documents
        case .decisions:
            return documents.filter { $0.analysis?.document_category == "Decision" }
        case .penalties:
            return documents.filter { $0.analysis?.document_category == "Penalty" }
        case .grid:
            return documents.filter {
                ($0.title?.localizedCaseInsensitiveContains("Grid") ?? false) ||
                ($0.analysis?.document_category == "Grid" )
            }
        }
    }

    @MainActor
    private func load() async {
        isLoading = true
        errorMessage = nil

        do {
            async let docs = F1LivePulseService.fetchFIADocuments()
            documents = try await docs
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

// MARK: - Document Row (Redesigned)

struct DocumentRow: View {
    let document: FIADocument
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main card (always visible)
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            } label: {
                VStack(alignment: .leading, spacing: 10) {
                    // Top row: Category icon + priority + category label + time
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

                        // Date
                        if let date = document.formattedDate {
                            Text(date)
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.35))
                        }
                    }

                    // Title
                    Text(document.title ?? "Untitled Document")
                        .font(.subheadline).bold()
                        .foregroundStyle(.white)
                        .lineLimit(isExpanded ? nil : 2)

                    // Summary (always visible, truncated)
                    if let summary = document.analysis?.short_summary {
                        Text(summary)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.65))
                            .lineLimit(isExpanded ? nil : 2)
                    }

                    // Inline badge row: drivers + penalty description
                    HStack(spacing: 8) {
                        // Driver chips
                        if let drivers = document.analysis?.drivers_involved, !drivers.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 4) {
                                    ForEach(drivers, id: \.self) { number in
                                        Text("#\\(number)")
                                            .font(.caption2).bold()
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(document.isPenalty ? Color.red.opacity(0.2) : document.categoryColor.opacity(0.15))
                                            .foregroundStyle(document.isPenalty ? .red : document.categoryColor)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                            .frame(maxWidth: 140)
                        }

                        // Penalty description badge
                        if let details = document.analysis?.details,
                           let desc = details.penaltyDescription {
                            HStack(spacing: 3) {
                                Image(systemName: details.penaltyIconName)
                                    .font(.caption2)
                                Text(desc)
                                    .font(.caption2).bold()
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.15))
                            .foregroundStyle(.red)
                            .clipShape(Capsule())
                        }

                        // Driver count for multi-driver docs
                        if let drivers = document.analysis?.drivers_involved, drivers.count > 3 {
                            Text("+\\(drivers.count - 3)")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.4))
                        }
                    }
                }
            }
            .buttonStyle(.plain)

            // Expanded section
            if isExpanded {
                expandedContent
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 8)
            }

            // Expand/collapse indicator
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
                    // Left accent border based on priority
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
                RoundedRectangle(cornerRadius: 2)
                    .fill(document.priorityDisplayColor)
                    .frame(width: 4)
                    .padding(.vertical, 8)
                    .padding(.leading, 0)
            }
                )
        )
        .padding(.vertical, 4)
    }

    // MARK: - Expanded Content

    @ViewBuilder
    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Full summary
            if let summary = document.analysis?.short_summary {
                Text(summary)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
                    .lineSpacing(3)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // Structured penalty data grid
            if let details = document.analysis?.details {
                let hasData = details.duration_in_seconds != nil
                    || details.fine_amount != nil
                    || details.grid_position_change != nil
                    || details.points != nil
                    || details.total_points_in_last_12_months != nil

                if hasData {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        if let seconds = details.duration_in_seconds {
                            penaltyDataCell(
                                icon: "clock.badge.exclamationmark",
                                label: "Duration",
                                value: seconds >= 60 ? "\\(seconds / 60)m \\(seconds % 60)s" : "\\(seconds)s",
                                color: .red
                            )
                        }
                        if let fine = details.fine_amount, fine > 0 {
                            penaltyDataCell(
                                icon: "dollarsign.circle",
                                label: "Fine",
                                value: "€\\(fine)",
                                color: .orange
                            )
                        }
                        if let gridDrop = details.grid_position_change, gridDrop > 0 {
                            penaltyDataCell(
                                icon: "arrow.down.circle",
                                label: "Grid Drop",
                                value: "\\(gridDrop) places",
                                color: .purple
                            )
                        }
                        if let pts = details.points, pts > 0 {
                            penaltyDataCell(
                                icon: "exclamationmark.circle",
                                label: "License Points",
                                value: "\\(pts) pts",
                                color: .yellow
                            )
                        }
                        if let totalPts = details.total_points_in_last_12_months, totalPts > 0 {
                            penaltyDataCell(
                                icon: "chart.line.uptrend.xyaxis",
                                label: "12mo Total",
                                value: "\\(totalPts) pts",
                                color: .white
                            )
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                // Full reasoning
                if let reasoning = details.reasoning {
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

                // Decision type
                if let decision = details.effectiveDecisionType {
                    HStack(spacing: 6) {
                        Image(systemName: details.penaltyIconName)
                            .font(.caption)
                        Text("Decision:")
                            .font(.caption).bold()
                        Text(decision.replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(.caption)
                    }
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }

            // All drivers involved chip row
            if let drivers = document.analysis?.drivers_involved, !drivers.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Drivers Involved")
                        .font(.caption).bold()
                        .foregroundStyle(.white.opacity(0.5))

                    FlexibleDriverChips(drivers: drivers, isPenalty: document.isPenalty)
                }
            }

            // Documents count for scrutineering/event info
            if document.isTechnical || document.isEventInfo,
               let summary = document.analysis?.short_summary {
                Text(summary)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }

            // Link to official document
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
                    .foregroundStyle(document.categoryColor)
                    .padding(.vertical, 4)
                }
            }

            // Navigation to Session Detail
            if document.isRaceClassification || document.isChampionshipPoints {
                NavigationLink {
                    F1SessionDetailView()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "flag.checkered")
                            .font(.caption)
                        Text("View Full Session Detail \u{2192}")
                            .font(.caption).bold()
                    }
                    .foregroundStyle(.red)
                }
            }
        }
    }

    private func penaltyDataCell(icon: String, label: String, value: String, color: Color) -> some View {
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

// MARK: - Flexible Driver Chips

struct FlexibleDriverChips: View {
    let drivers: [String]
    let isPenalty: Bool

    var body: some View {
        let rows = drivers.chunked(into: 6)

        VStack(alignment: .leading, spacing: 4) {
            ForEach(rows.indices, id: \.self) { rowIndex in
                HStack(spacing: 4) {
                    ForEach(rows[rowIndex], id: \.self) { number in
                        Text("#\\(number)")
                            .font(.caption2).bold()
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(isPenalty ? Color.red.opacity(0.15) : Color.blue.opacity(0.15))
                            .foregroundStyle(isPenalty ? .red : .blue)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }
}

// MARK: - Array Chunking

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

#Preview {
    NavigationStack {
        F1LiveFeedView()
    }
}
