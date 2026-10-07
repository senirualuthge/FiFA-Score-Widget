import SwiftUI

/// Sections shown in the F1 dashboard's segmented picker.
enum DashboardSection: String, CaseIterable {
    case overview = "Race Hub"
    case standings = "Standings"
    case live = "Live"
}

/// Reusable segmented picker for the F1 dashboard tabs.
///
/// Renders a segmented control with all `DashboardSection` cases,
/// showing a red live indicator dot on the "Live" tab.
///
/// Usage:
/// ```swift
/// @State private var section: DashboardSection = .overview
///
/// F1TabPicker(selection: $section)
/// ```
struct F1TabPicker: View {
    @Binding var selection: DashboardSection

    var body: some View {
        Picker("Section", selection: $selection) {
            ForEach(DashboardSection.allCases, id: \.self) { section in
                HStack(spacing: 4) {
                    if section == .live {
                        Circle()
                            .fill(.red)
                            .frame(width: 6, height: 6)
                    }
                    Text(section.rawValue)
                }
                .tag(section)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

#Preview {
    F1TabPicker(selection: .constant(.overview))
        .preferredColorScheme(.dark)
}
