import WidgetKit
import SwiftUI

struct WorldCupWidget: Widget {
    let kind: String = "WorldCupWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: WorldCupConfigurationIntent.self,
            provider: WorldCupProvider()
        ) { entry in
            WorldCupWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    WorldCupBackground(isLive: !entry.snapshot.liveMatches.isEmpty)
                }
        }
        .contentMarginsDisabled()   // we control all margins ourselves via .padding in each view
        .configurationDisplayName("World Cup")
        .description("Live scores, standings, and upcoming fixtures.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

@main
struct WorldCupWidgetBundle: WidgetBundle {
    var body: some Widget {
        WorldCupWidget()
    }
}

// MARK: - Dynamic background

/// Stadium-pitch-style gradient background. Shifts to a warm red-orange
/// while a match is live, and settles back to green otherwise. Purely
/// decorative — sits behind `WorldCupWidgetView`'s content and watermark,
/// and never affects layout, so it can't overlap or crowd out the scores.
private struct WorldCupBackground: View {
    let isLive: Bool

    private var topColor: Color {
        isLive ? Color(red: 0.32, green: 0.10, blue: 0.05)
               : Color(red: 0.05, green: 0.16, blue: 0.09)
    }

    private var bottomColor: Color {
        isLive ? Color(red: 0.16, green: 0.04, blue: 0.02)
               : Color(red: 0.03, green: 0.08, blue: 0.05)
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [topColor, bottomColor],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            GeometryReader { geo in
                Path { path in
                    let midY = geo.size.height * 0.5
                    path.move(to: CGPoint(x: 0, y: midY))
                    path.addLine(to: CGPoint(x: geo.size.width, y: midY))
                }
                .stroke(Color.white.opacity(0.05), lineWidth: 1)

                Circle()
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    .frame(width: geo.size.width * 0.35)
                    .position(x: geo.size.width * 0.5, y: geo.size.height * 0.5)
            }
        }
        .animation(.easeInOut(duration: 0.6), value: isLive)
    }
}
