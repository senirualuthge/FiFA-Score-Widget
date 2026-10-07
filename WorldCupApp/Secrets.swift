//  Secrets.swift
//  WorldCupApp
//
//  Created by Cs on 2026-07-09.
//

import Foundation

/// API keys used by the app.
///
/// - `footballDataAPIKey`: For football-data.org (World Cup data) — set in Info.plist as `FootballDataAPIKey`.
/// - `openF1LiveKey`: For OpenF1 real-time/live data access.
///
/// ⚠️ Never commit real keys to version control. This file is already gitignored.
enum Secrets {
    /// RapidAPI marketplace key.
    static let rapidAPIKey = "e47704fbf8msh308771d1b7ab424p118219jsnd92f468a92c5"
    
    /// RapidAPI hosts for F1 services.
    static let f1LivePulseHost = "f1-live-pulse.p.rapidapi.com"                  // F1 Live Pulse
    static let f1MotorsportHost = "f1-live-motorsport-data.p.rapidapi.com"       // F1 Live Motorsport Data
    static let f1MotorsportDataHost = "f1-motorsport-data.p.rapidapi.com"        // F1 Motorsport Data
}
