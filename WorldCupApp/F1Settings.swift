import Foundation
import SwiftUI
import Combine

/// Persistent settings for the F1 dashboard.
/// Each property is backed by `@AppStorage` so changes survive across app launches
/// and are automatically observed by SwiftUI views.
final class F1Settings: ObservableObject {
    
    // MARK: - Keys
    private enum Keys {
        static let darkMode = "F1.darkMode"
        static let liveStatusBar = "F1.liveStatusBar"
        static let openF1Enabled = "F1.openF1Enabled"
        static let defaultTab = "F1.defaultTab"
        static let showDocBadges = "F1.showDocBadges"
    }
    
    // MARK: - Defaults
    private enum Defaults {
        static let darkMode = true
        static let liveStatusBar = true
        static let openF1Enabled = true
        static let defaultTab = "Race Hub"
        static let showDocBadges = true
    }
    
    // MARK: - Published Properties
    
    /// When true, forces dark appearance. When false, follows system setting.
    @Published var useDarkMode: Bool {
        didSet {
            UserDefaults.standard.set(useDarkMode, forKey: Keys.darkMode)
        }
    }
    
    /// Show the live status bar at the top of the dashboard.
    @Published var showLiveStatusBar: Bool {
        didSet {
            UserDefaults.standard.set(showLiveStatusBar, forKey: Keys.liveStatusBar)
        }
    }
    
    /// Enable OpenF1 data fetching (historical data is free).
    @Published var openF1Enabled: Bool {
        didSet {
            UserDefaults.standard.set(openF1Enabled, forKey: Keys.openF1Enabled)
        }
    }
    
    /// Last selected tab in the dashboard.
    @Published var defaultTab: String {
        didSet {
            UserDefaults.standard.set(defaultTab, forKey: Keys.defaultTab)
        }
    }
    
    /// Show priority/document badges on cards.
    @Published var showDocBadges: Bool {
        didSet {
            UserDefaults.standard.set(showDocBadges, forKey: Keys.showDocBadges)
        }
    }
    
    // MARK: - Computed Properties
    
    /// The color scheme to apply to the dashboard.
    var preferredColorScheme: ColorScheme? {
        useDarkMode ? .dark : nil  // nil = follow system
    }
    
    // MARK: - Init
    
    init() {
        let defaults = UserDefaults.standard
        self._useDarkMode = Published(initialValue: defaults.object(forKey: Keys.darkMode) as? Bool ?? Defaults.darkMode)
        self._showLiveStatusBar = Published(initialValue: defaults.object(forKey: Keys.liveStatusBar) as? Bool ?? Defaults.liveStatusBar)
        self._openF1Enabled = Published(initialValue: defaults.object(forKey: Keys.openF1Enabled) as? Bool ?? Defaults.openF1Enabled)
        self._defaultTab = Published(initialValue: defaults.string(forKey: Keys.defaultTab) ?? Defaults.defaultTab)
        self._showDocBadges = Published(initialValue: defaults.object(forKey: Keys.showDocBadges) as? Bool ?? Defaults.showDocBadges)
    }
    
    // MARK: - Reset
    
    func resetAll() {
        useDarkMode = Defaults.darkMode
        showLiveStatusBar = Defaults.liveStatusBar
        openF1Enabled = Defaults.openF1Enabled
        defaultTab = Defaults.defaultTab
        showDocBadges = Defaults.showDocBadges
    }
}
