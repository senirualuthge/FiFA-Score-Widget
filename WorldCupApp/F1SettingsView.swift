import SwiftUI

/// Settings panel for the F1 dashboard — toggles for dark mode,
/// live data preferences, and display options. All changes persist
/// immediately via `F1Settings`.
struct F1SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var settings: F1Settings
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - Appearance Section
                    sectionHeader("Appearance", icon: "paintbrush.fill")
                    
                    VStack(spacing: 0) {
                        settingsRow(
                            icon: useDarkModeIcon,
                            iconColor: .blue,
                            title: "Dark Mode",
                            subtitle: settings.useDarkMode ? "Force dark appearance" : "Follow system setting"
                        ) {
                            Toggle("", isOn: $settings.useDarkMode)
                                .tint(.blue)
                        }
                        
                        Divider().background(.white.opacity(0.1))
                        
                        settingsRow(
                            icon: "doc.text.badge.ellipsis",
                            iconColor: .purple,
                            title: "Document Badges",
                            subtitle: "Show priority badges on FIA documents"
                        ) {
                            Toggle("", isOn: $settings.showDocBadges)
                                .tint(.purple)
                        }
                    }
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    
                    // MARK: - Data Section
                    sectionHeader("Data Sources", icon: "antenna.radiowaves.left.and.right")
                    
                    VStack(spacing: 0) {
                        settingsRow(
                            icon: "chart.bar.fill",
                            iconColor: .green,
                            title: "OpenF1 Data",
                            subtitle: settings.openF1Enabled
                                ? "Fetch historical session data (free)"
                                : "OpenF1 fetching disabled"
                        ) {
                            Toggle("", isOn: $settings.openF1Enabled)
                                .tint(.green)
                        }
                        
                        Divider().background(.white.opacity(0.1))
                        
                        settingsRow(
                            icon: "eye.fill",
                            iconColor: .orange,
                            title: "Live Status Bar",
                            subtitle: settings.showLiveStatusBar
                                ? "Show live indicator at top of dashboard"
                                : "Live status bar hidden"
                        ) {
                            Toggle("", isOn: $settings.showLiveStatusBar)
                                .tint(.orange)
                        }
                    }
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    
                    // MARK: - Data Attribution
                    VStack(spacing: 6) {
                        Text("Data Sources")
                            .font(.caption).bold()
                            .foregroundStyle(.white.opacity(0.5))
                        
                        VStack(spacing: 4) {
                            sourceRow("f1api.dev", description: "Free, no API key required")
                            sourceRow("F1 Live Pulse", description: "Via RapidAPI (subscription)")
                            sourceRow("OpenF1", description: "Historical data is free")
                        }
                        .padding(.vertical, 4)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // MARK: - Reset
                    Button(role: .destructive) {
                        settings.resetAll()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset All Settings")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.red.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.red.opacity(0.15), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding()
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.08, green: 0.08, blue: 0.12),
                        Color(red: 0.15, green: 0.04, blue: 0.04)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("F1 Settings")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .font(.subheadline).bold()
                        .foregroundStyle(.red)
                }
            }
        }
    }
    
    // MARK: - Helper Views
    
    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
            Text(title)
                .font(.caption).bold()
            Spacer()
        }
        .foregroundStyle(.white.opacity(0.5))
        .padding(.horizontal, 4)
    }
    
    private func settingsRow<Content: View>(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(iconColor)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline).bold()
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.4))
            }
            
            Spacer()
            
            content()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
    
    private var useDarkModeIcon: String {
        settings.useDarkMode ? "moon.fill" : "sun.max.fill"
    }
    
    private func sourceRow(_ name: String, description: String) -> some View {
        HStack {
            Text(name)
                .font(.caption).bold()
                .foregroundStyle(.white.opacity(0.7))
            Spacer()
            Text(description)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.35))
        }
    }
}

#Preview {
    F1SettingsView(settings: F1Settings())
}
