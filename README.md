# FIFA World Cup Score Widget

An iOS app + home screen widget to track FIFA World Cup matches, live scores, and group standings using [football-data.org](https://www.football-data.org/).

## Setup (Secure API Key)

This project reads `FootballDataAPIKey` from Info.plist via `$(FOOTBALL_DATA_API_KEY)`. 

### For new clones

1. Copy the example config
   ```bash
   cd "/Volumes/Volumn 1/Code Base/FIFA/WorldCupApp"
   cp Config.example.xcconfig Config.local.xcconfig
   ```

2. Add your API key to `Config.local.xcconfig`
   ```xcconfig
   FOOTBALL_DATA_API_KEY = YOUR_API_KEY_HERE
   ```

3. In Xcode, assign `Config.local.xcconfig` to your build configuration (Debug) for the project. The Info.plist files already reference `$(FOOTBALL_DATA_API_KEY)`, so both the app and widget will pick it up.

4. Run with `Cmd+R`.

### Notes

- `Config.local.xcconfig` is **gitignored** - your real key stays on your machine only.
- `Config.example.xcconfig` is committed as a template.
- The old hardcoded key was removed from `Info.plist` files.
- Never commit your real API key.

## Git usage

```bash
git clone https://github.com/senirualuthge/FiFA-Score-Widget.git
cd FiFA-Score-Widget
# set up Config.local.xcconfig as above
git status
git add .
git commit -m "your message"
git push
```

## App Group

If you change the App Group ID, update `appGroupID` in `WorldCupService.swift` for both app and widget targets.

## Repository

- GitHub: https://github.com/senirualuthge/FiFA-Score-Widget
- Issues/PRs welcome
