import AppIntents
import WidgetKit

// MARK: - Team entity (unchanged)

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

    static let allTeams: [TeamEntity] = [
        "Argentina", "Brazil", "France", "Spain", "England", "Germany",
        "Portugal", "Belgium", "Morocco", "Norway", "USA", "Mexico"
    ].map { TeamEntity(id: $0, name: $0) }
}

// MARK: - Widget page enum

/// Four pages that cycle through the widget. Raw value = stable index.
enum WidgetPage: Int, CaseIterable {
    case worldCup         = 0
    case f1NextRace       = 1
    case f1Drivers        = 2
    case f1Constructors   = 3

    var title: String {
        switch self {
        case .worldCup:        return "⚽ World Cup"
        case .f1NextRace:      return "🏎️ Next Race"
        case .f1Drivers:       return "🏎️ Drivers"
        case .f1Constructors:  return "🏎️ Constructors"
        }
    }

    func next() -> WidgetPage { WidgetPage(rawValue: (rawValue + 1) % WidgetPage.allCases.count)! }
    func prev() -> WidgetPage { WidgetPage(rawValue: (rawValue - 1 + WidgetPage.allCases.count) % WidgetPage.allCases.count)! }
}

// MARK: - Configuration intent

struct WorldCupConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "World Cup Widget"
    static var description = IntentDescription("Follow a specific team, or leave blank for live/next match.")

    @Parameter(title: "Favorite Team", default: nil)
    var favoriteTeam: TeamEntity?

    /// Current page index — updated by NextPageIntent / PrevPageIntent.
    @Parameter(title: "Page", default: 0)
    var displayPage: Int
}

// MARK: - Next page intent
// Conforms to SetValueIntent so WidgetKit re-renders the widget immediately
// with the updated configuration value, without a full timeline reload.

struct NextPageIntent: SetValueIntent {
    static var title: LocalizedStringResource = "Next Widget Page"

    /// The parameter that WidgetKit will update on the stored configuration.
    @Parameter(title: "Page")
    var value: Int

    init() { value = 0 }
    init(nextPage: Int) { value = nextPage }

    /// The keyPath on WorldCupConfigurationIntent that this intent sets.
    static var parameterKeyPath: WritableKeyPath<WorldCupConfigurationIntent, Int> {
        \.displayPage
    }

    func perform() async throws -> some IntentResult { .result() }
}

// MARK: - Prev page intent

struct PrevPageIntent: SetValueIntent {
    static var title: LocalizedStringResource = "Previous Widget Page"

    @Parameter(title: "Page")
    var value: Int

    init() { value = 0 }
    init(prevPage: Int) { value = prevPage }

    static var parameterKeyPath: WritableKeyPath<WorldCupConfigurationIntent, Int> {
        \.displayPage
    }

    func perform() async throws -> some IntentResult { .result() }
}
