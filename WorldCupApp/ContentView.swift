import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .worldCup

    enum Tab: String, CaseIterable {
        case worldCup = "World Cup"
        case f1 = "Formula 1"

        var icon: String {
            switch self {
            case .worldCup: return "soccerball"
            case .f1: return "flag.checkered"
            }
        }

        var activeIcon: String {
            switch self {
            case .worldCup: return "soccerball.circle.fill"
            case .f1: return "flag.checkered.2.crossed"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            // World Cup Tab
            NavigationStack {
                TeamSquadView()
                    .preferredColorScheme(.dark)
                    .tint(.yellow)
            }
            .tabItem {
                Label {
                    Text(Tab.worldCup.rawValue)
                } icon: {
                    Image(systemName: selectedTab == .worldCup ? Tab.worldCup.activeIcon : Tab.worldCup.icon)
                }
            }
            .tag(Tab.worldCup)

            // Formula 1 Tab
            F1DashboardView()
                .tabItem {
                    Label {
                        Text(Tab.f1.rawValue)
                    } icon: {
                        Image(systemName: selectedTab == .f1 ? Tab.f1.activeIcon : Tab.f1.icon)
                    }
                }
                .tag(Tab.f1)
        }
    }
}

#Preview {
    ContentView()
}
