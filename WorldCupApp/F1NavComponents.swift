import SwiftUI

// MARK: - Nav Pill

/// Compact navigation button pill used in the Standings tab for quick links.
struct NavPill<Destination: View>: View {
    let title: String
    let icon: String
    let color: Color
    let destination: Destination

    var body: some View {
        NavigationLink {
            destination
        } label: {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption).bold()
            }
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(color.opacity(0.2), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    init(title: String, icon: String, color: Color, @ViewBuilder destination: () -> Destination) {
        self.title = title
        self.icon = icon
        self.color = color
        self.destination = destination()
    }
}

// MARK: - Mini Nav Card

/// Small navigation card for the 3-column quick-links grid in the overview tab.
struct MiniNavCard<Destination: View>: View {
    let title: String
    let icon: String
    let color: Color
    let destination: Destination

    var body: some View {
        NavigationLink(destination: destination) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption2).bold()
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(color.opacity(0.12), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    init(title: String, icon: String, color: Color, @ViewBuilder destination: () -> Destination) {
        self.title = title
        self.icon = icon
        self.color = color
        self.destination = destination()
    }
}

// MARK: - Nav Pill Small

/// Smaller navigation button with chevron, used in the Live tab's quick-access grid.
struct NavPillSmall<Destination: View>: View {
    let title: String
    let icon: String
    let color: Color
    let destination: Destination

    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption).bold()
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption2)
            }
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(color.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(color.opacity(0.15), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    init(title: String, icon: String, color: Color, @ViewBuilder destination: () -> Destination) {
        self.title = title
        self.icon = icon
        self.color = color
        self.destination = destination()
    }
}

#Preview("NavPill - All Colors") {
    HStack(spacing: 12) {
        NavPill(title: "Standings", icon: "trophy.fill", color: .yellow) { EmptyView() }
        NavPill(title: "Drivers", icon: "person.3.fill", color: .red) { EmptyView() }
        NavPill(title: "Teams", icon: "building.2.fill", color: .blue) { EmptyView() }
    }
    .padding()
    .background(Color(red: 0.08, green: 0.08, blue: 0.12))
    .preferredColorScheme(.dark)
}

#Preview("MiniNavCard - Grid") {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
        MiniNavCard(title: "Live Feed", icon: "antenna.radiowaves.left.and.right", color: .red) { EmptyView() }
        MiniNavCard(title: "Session", icon: "flag.checkered", color: .pink) { EmptyView() }
        MiniNavCard(title: "Telemetry", icon: "chart.xyaxis.line", color: .purple) { EmptyView() }
        MiniNavCard(title: "Standings", icon: "trophy.fill", color: .yellow) { EmptyView() }
        MiniNavCard(title: "Calendar", icon: "calendar", color: .green) { EmptyView() }
        MiniNavCard(title: "Drivers", icon: "person.3.fill", color: .red) { EmptyView() }
    }
    .padding()
    .background(Color(red: 0.08, green: 0.08, blue: 0.12))
    .preferredColorScheme(.dark)
}

#Preview("NavPillSmall - Grid") {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
        NavPillSmall(title: "Session Detail", icon: "flag.checkered", color: .pink) { EmptyView() }
        NavPillSmall(title: "Telemetry", icon: "chart.xyaxis.line", color: .purple) { EmptyView() }
        NavPillSmall(title: "Compare", icon: "arrow.left.arrow.right", color: .mint) { EmptyView() }
        NavPillSmall(title: "Standings", icon: "trophy.fill", color: .yellow) { EmptyView() }
    }
    .padding()
    .background(Color(red: 0.08, green: 0.08, blue: 0.12))
    .preferredColorScheme(.dark)
}

#Preview("Single Variants") {
    VStack(spacing: 12) {
        NavPill(title: "Standings", icon: "trophy.fill", color: .yellow) { EmptyView() }
        MiniNavCard(title: "Calendar", icon: "calendar", color: .green) { EmptyView() }
        NavPillSmall(title: "Telemetry", icon: "chart.xyaxis.line", color: .purple) { EmptyView() }
    }
    .padding()
    .background(Color(red: 0.08, green: 0.08, blue: 0.12))
    .preferredColorScheme(.dark)
}
