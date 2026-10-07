import SwiftUI

/// Full-screen app background: a stadium-pitch gradient with a faint
/// soccerball watermark, matching the widget's look. Drop this behind your
/// main app's content, e.g.:
///
///     ZStack {
///         WorldCupWallpaper()
///         YourExistingContent()
///     }
///
/// or as a `.background(WorldCupWallpaper())` modifier on your root view.
struct WorldCupWallpaper: View {
    var isLive: Bool = false
    @State private var phase: CGFloat = 0.0

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
                startPoint: UnitPoint(x: phase, y: 0.0),
                endPoint: UnitPoint(x: 1.0 - phase, y: 1.0)
            )
            .ignoresSafeArea()

            GeometryReader { geo in
                // Center circle + halfway line, low-opacity pitch markings
                Path { path in
                    let midY = geo.size.height * 0.42
                    path.move(to: CGPoint(x: 0, y: midY))
                    path.addLine(to: CGPoint(x: geo.size.width, y: midY))
                }
                .stroke(Color.white.opacity(0.05), lineWidth: 1)

                Circle()
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    .frame(width: geo.size.width * 0.55)
                    .position(x: geo.size.width * 0.5, y: geo.size.height * 0.42)

                Image(systemName: "soccerball")
                    .resizable()
                    .scaledToFit()
                    .frame(width: geo.size.width * 0.7)
                    .foregroundStyle(.white.opacity(0.05))
                    .position(x: geo.size.width * 0.82, y: geo.size.height * 0.88)
                    .rotationEffect(.degrees(phase * 30))
            }
            .ignoresSafeArea()
        }
        .animation(.easeInOut(duration: 0.6), value: isLive)
        .onAppear {
            withAnimation(.easeInOut(duration: 6.0).repeatForever(autoreverses: true)) {
                phase = 0.2
            }
        }
    }
}

#Preview {
    WorldCupWallpaper()
}
