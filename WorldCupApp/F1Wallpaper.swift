import SwiftUI

/// Full-screen F1-themed animated background that adapts to dark/light mode.
/// Dark mode: deep navy-to-burgundy gradient with subtle track elements.
/// Light mode: lighter gradient with softer accents.
struct F1Wallpaper: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var phase: CGFloat = 0.0

    private var isDark: Bool { colorScheme == .dark }

    private var topColor: Color {
        isDark
            ? Color(red: 0.08, green: 0.08, blue: 0.12)
            : Color(red: 0.92, green: 0.92, blue: 0.95)
    }
    private var bottomColor: Color {
        isDark
            ? Color(red: 0.15, green: 0.04, blue: 0.04)
            : Color(red: 0.95, green: 0.88, blue: 0.88)
    }
    private var accentColor: Color {
        Color(red: 0.90, green: 0.10, blue: 0.10)
    }

    private var gridColor: Color {
        isDark ? .white : .black
    }
    private var textColor: Color {
        isDark ? .white : .black
    }

    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [topColor, bottomColor],
                startPoint: UnitPoint(x: 0.0, y: 0.0),
                endPoint: UnitPoint(x: 1.0, y: 1.0)
            )
            .ignoresSafeArea()

            GeometryReader { geo in
                // Subtle grid lines (like a track map grid)
                ForEach(0..<12) { i in
                    let x = geo.size.width * CGFloat(i) / 12
                    Rectangle()
                        .fill(gridColor.opacity(isDark ? 0.02 : 0.03))
                        .frame(width: 1)
                        .position(x: x, y: geo.size.height / 2)
                        .frame(height: geo.size.height)
                }

                // Checkered flag pattern in bottom corner
                let squareSize: CGFloat = 12
                let cols = Int(geo.size.width * 0.25 / squareSize)
                let rows = 8
                VStack(spacing: 0) {
                    ForEach(0..<rows, id: \.self) { row in
                        HStack(spacing: 0) {
                            ForEach(0..<cols, id: \.self) { col in
                                Rectangle()
                                    .fill((row + col) % 2 == 0
                                          ? gridColor.opacity(isDark ? 0.04 : 0.06)
                                          : Color.clear)
                                    .frame(width: squareSize, height: squareSize)
                            }
                        }
                    }
                }
                .position(x: geo.size.width * 0.88, y: geo.size.height * 0.92)

                // Speed lines animation
                ForEach(0..<5) { i in
                    let offset = phase * 50 + CGFloat(i * 60)
                    RoundedRectangle(cornerRadius: 1)
                        .fill(accentColor.opacity(isDark ? 0.06 : 0.04))
                        .frame(width: 2, height: 60)
                        .offset(x: geo.size.width * 0.3 + offset.truncatingRemainder(dividingBy: geo.size.width * 0.4),
                                y: geo.size.height * 0.3 + CGFloat(i * 30))
                        .rotationEffect(.degrees(-30))
                }

                // F1 flag silhouette
                Image(systemName: "flag.checkered")
                    .resizable()
                    .scaledToFit()
                    .frame(width: geo.size.width * 0.3)
                    .foregroundStyle(textColor.opacity(isDark ? 0.04 : 0.06))
                    .position(x: geo.size.width * 0.78, y: geo.size.height * 0.15)
                    .rotationEffect(.degrees(-10))
            }
            .ignoresSafeArea()
        }
        .onAppear {
            withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
                phase = 1.0
            }
        }
    }
}

#Preview {
    F1Wallpaper()
}
