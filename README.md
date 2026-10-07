# FIFA World Cup Score Widget

An iOS app + home screen widget to track FIFA World Cup matches, live scores, and group standings using [football-data.org](https://www.football-data.org/).

## About

This project is an iOS SwiftUI app with a companion WidgetKit extension for quick at-a-glance World Cup scores. It fetches live data from the football-data.org API and caches results via an App Group so the widget stays up to date.

## Features

- Live, upcoming & recent matches
- Group standings
- Match details with venue/stage info
- iOS Lock/Home Screen Widget (shared cache via App Group)

## Setup (Secure API Key)

This project reads `FootballDataAPIKey` from Info.plist via `$(FOOTBALL_DATA_API_KEY)`. 

### For new clones

1. Copy the example config
   ```bash
   cd FiFA-Score-Widget
   cp Config.example.xcconfig Config.local.xcconfig
   ```

2. Add your API key to `Config.local.xcconfig`
   ```xcconfig
   FOOTBALL_DATA_API_KEY = YOUR_API_KEY_HERE
   ```

3. In Xcode, assign `Config.local.xcconfig` to your build configuration (Debug) for the project. The Info.plist files for both targets already reference `$(FOOTBALL_DATA_API_KEY)`.

4. Run with `Cmd+R`.

### Notes

- `Config.local.xcconfig` is **gitignored** - your real key stays on your machine only.
- `Config.example.xcconfig` is committed as a template.
- The hardcoded API key was removed from Info.plist files.
- Never commit your real API key.

## App Group

For the widget to read cached data from the app:
1. Open `WorldCupApp.xcodeproj` in Xcode
2. For **both** `WorldCupApp` and `WorldCupWidgetExtension` targets:
   - Signing & Capabilities → + App Groups
   - Enable `group.com.cs.worldcup` (update to match your bundle ID if changed)
3. If you change it, update `appGroupID` in `WorldCupService.swift` for both targets.




