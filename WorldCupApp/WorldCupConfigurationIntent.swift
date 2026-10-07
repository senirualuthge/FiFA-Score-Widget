import AppIntents
import WidgetKit

struct TeamEntity: AppEntity, Identifiable {
    let id: String
    let name: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Team"
    static var defaultQuery = TeamEntityQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

struct TeamEntityQuery: EntityQuery {
    func entities(for identifiers: [TeamEntity.ID]) async throws -> [TeamEntity] {
        Self.allTeams.filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [TeamEntity] {
        Self.allTeams
    }

    // Static list so the config sheet works instantly, offline, with no
    // network call — matches by name against Match.homeTeam/awayTeam later.
    static let allTeams: [TeamEntity] = [
        "Argentina", "Brazil", "France", "Spain", "England", "Germany",
        "Portugal", "Belgium", "Morocco", "Norway", "USA", "Mexico"
    ].map { TeamEntity(id: $0, name: $0) }
}

struct WorldCupConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "World Cup Widget"
    static var description = IntentDescription("Follow a specific team, or leave blank for live/next match.")

    @Parameter(title: "Favorite Team", default: nil)
    var favoriteTeam: TeamEntity?

    /// Current page index — updated by NextPageIntent / PrevPageIntent.
    @Parameter(title: "Page", default: 0)
    var displayPage: Int
}
