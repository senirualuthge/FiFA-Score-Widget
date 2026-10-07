import WidgetKit

struct WorldCupEntry: TimelineEntry {
    let date: Date
    let snapshot: WorldCupSnapshot
    let f1Snapshot: F1WidgetSnapshot
    let configuration: WorldCupConfigurationIntent
}

struct WorldCupProvider: AppIntentTimelineProvider {
    typealias Entry = WorldCupEntry
    typealias Intent = WorldCupConfigurationIntent

    func placeholder(in context: Context) -> WorldCupEntry {
        WorldCupEntry(
            date: Date(),
            snapshot: .placeholder,
            f1Snapshot: .placeholder,
            configuration: WorldCupConfigurationIntent()
        )
    }

    func snapshot(for configuration: WorldCupConfigurationIntent, in context: Context) async -> WorldCupEntry {
        async let wcSnap  = WorldCupService.fetchSnapshot()
        async let f1Snap  = F1WidgetService.fetchSnapshot()
        let (wc, f1) = await (wcSnap, f1Snap)
        return WorldCupEntry(date: Date(), snapshot: wc, f1Snapshot: f1, configuration: configuration)
    }

    func timeline(for configuration: WorldCupConfigurationIntent, in context: Context) async -> Timeline<WorldCupEntry> {
        async let wcSnap  = WorldCupService.fetchSnapshot()
        async let f1Snap  = F1WidgetService.fetchSnapshot()
        let (wc, f1) = await (wcSnap, f1Snap)

        let entry = WorldCupEntry(date: Date(), snapshot: wc, f1Snapshot: f1, configuration: configuration)

        let refreshInterval: TimeInterval
        if !wc.liveMatches.isEmpty {
            // Refresh every 10 seconds while a football match is in progress
            refreshInterval = 10
        } else {
            // No live match — refresh every 3 hours
            refreshInterval = 10_800
        }

        let nextUpdate = Date().addingTimeInterval(refreshInterval)
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }
}
