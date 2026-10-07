# ⚽ FIFA World Cup Score Widget

An iOS app and home screen widget for following the FIFA World Cup: live scores, fixtures, results, and group standings, powered by [football-data.org](https://www.football-data.org/).

## Features

- **Live, upcoming and recent matches** with real-time scores
- **Group standings** for every World Cup group
- **Match details** including venue and tournament stage
- **Home Screen and Lock Screen widget** for at-a-glance scores
- **Shared cache via App Group** so the widget stays fresh without extra API calls

## Tech Stack

| Area | Technology |
|---|---|
| UI | SwiftUI |
| Widget | WidgetKit |
| Data | [football-data.org](https://www.football-data.org/) REST API |
| App ↔ Widget sharing | App Groups |
| Config | `.xcconfig` (API key kept out of source control) |

## Requirements

- macOS with **Xcode 15+**
- iOS **17+**
- A free API key from [football-data.org](https://www.football-data.org/client/register)
- An Apple ID for signing (a free account works for running on your own device)

## Getting Started

### 1. Clone the repo

```bash
git clone https://github.com/senirualuthge/FiFA-Score-Widget.git
cd FiFA-Score-Widget
```

### 2. Add your API key

The app reads `FootballDataAPIKey` from `Info.plist`, which resolves to `$(FOOTBALL_DATA_API_KEY)` at build time.

```bash
cp Config.example.xcconfig Config.local.xcconfig
```

Open `Config.local.xcconfig` and set your key:

```xcconfig
FOOTBALL_DATA_API_KEY = YOUR_API_KEY_HERE
```

Then in Xcode, assign `Config.local.xcconfig` to the **Debug** configuration for the project. Both targets' `Info.plist` files already reference the variable.

> `Config.local.xcconfig` is gitignored, so your real key stays on your machine. Never commit it.

### 3. Configure the App Group

The widget reads cached data written by the app through a shared App Group.

1. Open `WorldCupApp.xcodeproj` in Xcode.
2. For **both** the `WorldCupApp` and `WorldCupWidgetExtension` targets, go to **Signing & Capabilities → + Capability → App Groups**.
3. Enable `group.com.cs.worldcup`.

If you change your bundle IDs and need a different group name, update `appGroupID` in `WorldCupService.swift` for both targets.

### 4. Run

Select the `WorldCupApp` scheme, choose a simulator or device, and press **Cmd+R**. Long-press the Home Screen and tap **+** to add the widget.
