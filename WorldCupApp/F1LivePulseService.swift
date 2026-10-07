import Foundation

/// Service for fetching live data from the F1 Live Pulse RapidAPI.
/// Requires an active subscription and the RapidAPI key from Secrets.swift.
enum F1LivePulseService {

    private static let host = Secrets.f1LivePulseHost
    private static let baseURL = "https://\(host)"

    // MARK: - FIA Documents

    /// Fetches official FIA documents (stewards' decisions, penalties, classifications, etc.)
    static func fetchFIADocuments() async throws -> [FIADocument] {
        let response = try await fetchFIADocumentsResponse()
        return response.documents
    }

    /// Fetches the full FIA documents response including event name and meeting index.
    static func fetchFIADocumentsResponse() async throws -> FIADocumentsResponse {
        let data = try await request("/fiaDocuments")
        return try JSONDecoder().decode(FIADocumentsResponse.self, from: data)
    }

    // MARK: - Driver List

    /// Fetches the current list of F1 drivers from the live data source.
    static func fetchDriverList() async throws -> [F1LivePulseDriver] {
        let data = try await request("/driverList")
        return try JSONDecoder().decode([F1LivePulseDriver].self, from: data)
    }

    // MARK: - Generic RapidAPI Request

    private static func request(_ path: String) async throws -> Data {
        guard let url = URL(string: baseURL + path) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(host, forHTTPHeaderField: "x-rapidapi-host")
        request.setValue(Secrets.rapidAPIKey, forHTTPHeaderField: "x-rapidapi-key")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200...299).contains(http.statusCode) else {
            // Try to extract error message from response
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let message = errorJson["message"] as? String {
                throw F1PulseError.apiError(message)
            }
            throw URLError(.badServerResponse)
        }

        return data
    }
}

enum F1PulseError: LocalizedError {
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .apiError(let message):
            return "F1 Live Pulse: \(message)"
        }
    }
}
