import SwiftUI

struct F1CircuitListView: View {
    @State private var circuits: [F1Circuit] = []
    @State private var isLoading = true
    @State private var searchText = ""
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            F1Wallpaper()
            
            Group {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else if let errorMessage {
                    VStack(spacing: 12) {
                        Text(errorMessage).foregroundStyle(.white.opacity(0.8))
                        Button("Retry") { Task { await load() } }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        ForEach(filteredCircuits, id: \.id) { circuit in
                            CircuitRow(circuit: circuit)
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .searchable(text: $searchText, prompt: "Search circuits by name, country, or city")
                }
            }
        }
        .navigationTitle("Circuits")
        .task { await load() }
    }
    
    private var filteredCircuits: [F1Circuit] {
        guard !searchText.isEmpty else { return circuits }
        return circuits.filter { circuit in
            (circuit.circuitName?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            (circuit.country?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            (circuit.city?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    @MainActor
    private func load() async {
        isLoading = true
        errorMessage = nil
        
        do {
            circuits = try await F1Service.fetchCircuits()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - Circuit Row

struct CircuitRow: View {
    let circuit: F1Circuit
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(circuit.circuitName ?? "")
                        .font(.body).bold()
                    Text(circuit.location)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
                
                Spacer()
                
                if let corners = circuit.corners {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(corners)")
                            .font(.headline).bold()
                        Text("corners")
                            .font(.caption2)
                    }
                    .foregroundStyle(.white.opacity(0.5))
                }
            }
            
            HStack(spacing: 12) {
                if let length = circuit.circuitLength {
                    Label("\(length) km", systemImage: "arrow.triangle.swap")
                        .font(.caption)
                }
                if let firstYear = circuit.firstParticipationYear {
                    Label("Since \(firstYear)", systemImage: "calendar")
                        .font(.caption)
                }
            }
            .foregroundStyle(.white.opacity(0.5))
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        F1CircuitListView()
    }
}
