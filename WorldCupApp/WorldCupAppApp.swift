import SwiftUI
import WidgetKit

//  WorldCupAppApp.swift
//  WorldCupApp
//
//  Created by Cs on 2026-07-09.
//

@main
struct WorldCupAppApp: App {
    
    init() {
        customTabBarAppearance()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    /// Configures the global tab bar appearance for a dark, translucent look.
    private func customTabBarAppearance() {
        #if os(iOS)
        let appearance = UITabBarAppearance()
        
        // Dark translucent background with blur
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        appearance.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        
        // Remove the top border line
        appearance.shadowColor = .clear
        appearance.shadowImage = nil
        
        // Normal (unselected) state — subtle light gray
        let normalAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.white.withAlphaComponent(0.5),
            .font: UIFont.systemFont(ofSize: 10, weight: .medium)
        ]
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = normalAttributes
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.white.withAlphaComponent(0.5)
        
        // Selected state — bright white
        let selectedAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
        ]
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedAttributes
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor.white
        
        // Apply to all tab bar appearances
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        #endif
    }
}
