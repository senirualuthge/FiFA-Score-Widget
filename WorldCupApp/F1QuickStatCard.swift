import SwiftUI

/// Compact stat card showing a single metric with icon and color accent.
/// Used in the overview tab's quick stats row.
struct QuickStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                Text(title)
                    .font(.caption2)
            }
            .foregroundStyle(color)

            Text(value)
                .font(.title2).bold()

            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.5))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.15), lineWidth: 1)
                )
        )
    }
}

#Preview("Drivers - Yellow") {
    QuickStatCard(
        title: "Drivers",
        value: "20",
        subtitle: "VER leads",
        icon: "person.3.fill",
        color: .yellow
    )
    .preferredColorScheme(.dark)
}

#Preview("Constructors - Blue") {
    QuickStatCard(
        title: "Constructors",
        value: "10",
        subtitle: "Red Bull Racing",
        icon: "building.2.fill",
        color: .blue
    )
    .preferredColorScheme(.dark)
}

#Preview("Races - Green") {
    QuickStatCard(
        title: "Races",
        value: "24",
        subtitle: "2026 season",
        icon: "flag.checkered",
        color: .green
    )
    .preferredColorScheme(.dark)
}

#Preview("Row Layout") {
    HStack(spacing: 12) {
        QuickStatCard(title: "Drivers", value: "20", subtitle: "VER leads", icon: "person.3.fill", color: .yellow)
        QuickStatCard(title: "Races", value: "24", subtitle: "2026 season", icon: "flag.checkered", color: .green)
    }
    .padding()
    .background(Color(red: 0.08, green: 0.08, blue: 0.12))
    .preferredColorScheme(.dark)
}
