import Foundation

let apiKey = "7295e5653ffc4382a4a7dd190478aade"
let baseURL = "https://api.football-data.org/v4"

func request(_ path: String) async throws -> Data {
    var request = URLRequest(url: URL(string: baseURL + path)!)
    request.setValue(apiKey, forHTTPHeaderField: "X-Auth-Token")
    let (data, response) = try await URLSession.shared.data(for: request)
    if let http = response as? HTTPURLResponse, http.statusCode != 200 {
        print("HTTP \(http.statusCode) for \(path)")
    }
    return data
}

Task {
    do {
        let matchesData = try await request("/competitions/WC/matches")
        print("Decoding matches...")
        let decodedMatches = try JSONDecoder().decode(MatchesResponse.self, from: matchesData)
        print("Matches decoded: \(decodedMatches.matches.count)")
        
        let standingsData = try await request("/competitions/WC/standings")
        print("Decoding standings...")
        let decodedStandings = try JSONDecoder().decode(StandingsResponse.self, from: standingsData)
        print("Standings decoded: \(decodedStandings.standings.count)")
        
        exit(0)
    } catch {
        print("Error: \(error)")
        exit(1)
    }
}

RunLoop.main.run()
