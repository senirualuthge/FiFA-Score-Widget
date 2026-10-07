import Foundation


enum WorldCupService {

    // World Cup competition code on football-data.org is "WC"
    private static let baseURL = "https://api.football-data.org/v4"
   
    /// Reads the API key from Info.plist (see README for setup).
    /// Never hardcode the key directly in source you commit to version control.
    private static var apiKey: String {
        Bundle.main.object(forInfoDictionaryKey: "FootballDataAPIKey") as? String ?? ""
    }

    // MARK: - Snapshot cache

    /// IMPORTANT: replace with your actual App Group identifier.
    /// Set this up once in Xcode: select BOTH the WorldCupApp target and the
    /// WorldCupWidgetExtension target → Signing & Capabilities → + Capability
    /// → App Groups → create/enable a group like "group.com.yourteam.worldcup".
    /// Both targets must use the SAME group id for this cache to be shared —
    /// without it, the widget process (sandboxed separately from the app)
    /// can't see anything the app fetched, and vice versa.
    private static let appGroupID = "group.com.cs.worldcup"
    private static let cacheKey = "WorldCupService.cachedSnapshot"

    private static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    private static func cacheSnapshot(_ snapshot: WorldCupSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        sharedDefaults?.set(data, forKey: cacheKey)
    }

    private static func cachedSnapshot() -> WorldCupSnapshot? {
        guard let data = sharedDefaults?.data(forKey: cacheKey) else { return nil }
        return try? JSONDecoder().decode(WorldCupSnapshot.self, from: data)
    }

    // MARK: - Networking

    private static func request(_ path: String) async throws -> Data {
        guard !apiKey.isEmpty else {
            throw NSError(
                domain: "WorldCupService",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: "API key not configured. Please set FootballDataAPIKey in Info.plist"]
            )
        }
        
        guard let components = URLComponents(string: baseURL + path) else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: components.url!)
        request.setValue(apiKey, forHTTPHeaderField: "X-Auth-Token")

        let (data, response) = try await URLSession.shared.data(for: request)

        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            if http.statusCode == 429 {
                print("⚠️ football-data.org rate limit hit (429) fetching \(path) — falling back to cached snapshot")
            }
            throw NSError(
                domain: "WorldCupService",
                code: http.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "HTTP \(http.statusCode) fetching \(path)"]
            )
        }
        return data
    }

    static func fetchMatches() async throws -> [Match] {
        let data = try await request("/competitions/WC/matches")
        do {
            let decoded = try JSONDecoder().decode(MatchesResponse.self, from: data)
            return decoded.matches
        } catch {
            print("RAW MATCHES RESPONSE: \(String(data: data, encoding: .utf8) ?? "unreadable")")
            throw error
        }
    }

    static func fetchStandings() async throws -> [StandingRow] {
        let data = try await request("/competitions/WC/standings")
        do {
            let decoded = try JSONDecoder().decode(StandingsResponse.self, from: data)
            // Flatten all groups, sorted by group then position, capped for widget display
            return decoded.standings.flatMap { $0.table }.sorted { $0.points > $1.points }
        } catch {
            print("RAW STANDINGS RESPONSE: \(String(data: data, encoding: .utf8) ?? "unreadable")")
            throw error
        }
    }

    /// Fetches venue, stage/group, and (plan-permitting) formations + lineups
    /// for a single match. Used by the main app's match detail / pitch view —
    /// not by the widget, which stays on the lighter list endpoints.
    static func fetchMatchDetail(id: Int) async throws -> MatchDetail {
        let data = try await request("/matches/\(id)")
        do {
            return try JSONDecoder().decode(MatchDetail.self, from: data)
        } catch {
            print("RAW MATCH DETAIL RESPONSE: \(String(data: data, encoding: .utf8) ?? "unreadable")")
            throw error
        }
    }

    /// Fetches every squad in the tournament (name, position, nationality per
    /// player) in a single call. Used for the main app's team/player detail
    /// screens — not the widget.
    static func fetchAllSquads() async throws -> [TeamDetail] {
        let data = try await request("/competitions/WC/teams")
        do {
            let decoded = try JSONDecoder().decode(CompetitionTeamsResponse.self, from: data)
            return decoded.teams
        } catch {
            print("RAW TEAMS RESPONSE: \(String(data: data, encoding: .utf8) ?? "unreadable")")
            throw error
        }
    }

    /// Fetches a fresh snapshot for the widget. On success, caches it to
    /// shared storage. On failure (rate limiting, transient network error,
    /// decoding issue), falls back to the last cached snapshot instead of
    /// `.placeholder` — this is what stops the widget from reverting to
    /// blank every time a single fetch fails. `.placeholder` is now only
    /// used as the very last resort, when there's no cache at all (e.g.
    /// first-ever launch before anything has succeeded once).
    static func fetchSnapshot() async -> WorldCupSnapshot {
        do {
            async let matches = fetchMatches()
            async let standings = fetchStandings()

            let (allMatches, table) = try await (matches, standings)

            let live = allMatches.filter { $0.isLive }

            let recent = allMatches
                .filter { $0.status == "FINISHED" }
                .sorted { ($0.kickoffDate ?? .distantPast) > ($1.kickoffDate ?? .distantPast) }
                .prefix(2)

            var upcoming = allMatches
                .filter { $0.status == "SCHEDULED" || $0.status == "TIMED" }
                .sorted { ($0.kickoffDate ?? .distantFuture) < ($1.kickoffDate ?? .distantFuture) }

            // football-data.org's free tier is often slow to populate
            // knockout-round fixtures (they can lag behind FIFA's official
            // schedule, especially around "Winner Match X" placeholders).
            // If the live upcoming list looks thin, top it up with our
            // hardcoded quarterfinal-through-final schedule so the widget
            // still shows the correct dates/venues either way.
            if upcoming.count < 3 {
                let known = Set(upcoming.map(\.id))
                let fallback = WorldCupFallbackFixtures.upcoming()
                    .filter { !known.contains($0.id) }
                upcoming.append(contentsOf: fallback)
                upcoming.sort { ($0.kickoffDate ?? .distantFuture) < ($1.kickoffDate ?? .distantFuture) }
            }

            let snapshot = WorldCupSnapshot(
                liveMatches: live,
                recentMatches: Array(recent),
                upcomingMatches: Array(upcoming.prefix(3)),
                topStandings: Array(table.prefix(5)),
                lastUpdated: Date()
            )

            cacheSnapshot(snapshot)
            return snapshot

        } catch {
            print("WorldCupService error: \(error) — attempting cached snapshot fallback")
            if let cached = cachedSnapshot() {
                print("✅ using cached snapshot from \(cached.lastUpdated)")
                return cached
            }
            print("⚠️ no cached snapshot available — falling back to static fixture schedule")
            return WorldCupSnapshot(
                liveMatches: [],
                recentMatches: [],
                upcomingMatches: Array(WorldCupFallbackFixtures.upcoming().prefix(3)),
                topStandings: [],
                lastUpdated: Date()
            )
        }
    }
}
