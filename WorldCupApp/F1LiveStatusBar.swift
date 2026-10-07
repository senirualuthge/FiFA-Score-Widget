import SwiftUI

/// Compact live indicator showing current FIA event, document count, and calendar link.
struct F1LiveStatusBar: View {
    let eventName: String
    let docCount: Int

    var body: some View {
        HStack(spacing: 8) {
            // Live indicator
            HStack(spacing: 4) {
                Circle()
                    .fill(.red)
                    .frame(width: 6, height: 6)
                Text("LIVE")
                    .font(.caption2).bold()
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.red.opacity(0.2))
            .clipShape(Capsule())

            // Event name
            if !eventName.isEmpty {
                Text(eventName)
                    .font(.caption).bold()
                    .foregroundStyle(.white)
            }

            Spacer()

            // Documents count
            if docCount > 0 {
                NavigationLink {
                    F1LiveFeedView()
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "doc.text.fill")
                            .font(.caption2)
                        Text("\(docCount) docs")
                            .font(.caption2)
                    }
                    .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            }

            // Calendar link
            NavigationLink {
                F1RaceCalendarView()
            } label: {
                Image(systemName: "calendar")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.4))
    }
}

#Preview {
    F1LiveStatusBar(eventName: "Singapore Grand Prix", docCount: 12)
        .preferredColorScheme(.dark)
}
