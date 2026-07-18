# VoltPeek

Native macOS menu bar app for live battery and charging telemetry — watts, current, voltage, temperature, health, cycles, and adapter details.

**Requirements:** macOS 14+ · Apple Silicon or Intel · no account, no network

Support: [hello@voltpeek.app](mailto:hello@voltpeek.app)

---

## Install

### Homebrew

```bash
brew install --cask kumarprabhakar2121/tap/voltpeek
```

Details: [docs/HOMEBREW.md](docs/HOMEBREW.md). First launch may need right-click → Open until the app is notarized.

### Mac App Store

Planned as a free listing (requires Apple Developer Program). See [docs/RELEASE.md](docs/RELEASE.md).

### Build from source

```bash
brew install xcodegen   # if needed
cd /path/to/VoltPeek
xcodegen generate
open VoltPeek.xcodeproj
```

Build and run the **VoltPeek** scheme. The app appears in the menu bar only (no Dock icon).

---

## Features

- Live signed power (W), current (A), voltage, temperature
- Battery %, charging status, time remaining, health, cycle count, max capacity
- Adapter connected state, wattage, and name
- Menu bar styles: Text, Battery, Battery + %, Bolt, Bolt + Watts, Battery (auto bolt)
- Popover themes: **List**, **Cards**, **Glass**
- Display Size, accessibility overrides, refresh interval (0.5–10 s)
- Power Graph tab (last ~60 s wattage)
- Launch at Login, Reset All Settings

---

## Privacy

VoltPeek reads battery data **locally** via IOKit. It does not collect analytics, sell data, or require sign-in.

- Policy (Markdown): [docs/PRIVACY.md](docs/PRIVACY.md)
- **App Store Privacy URL:** https://kumarprabhakar2121.github.io/VoltPeek/privacy.html
- Support: https://kumarprabhakar2121.github.io/VoltPeek/support.html

---

## Development

```bash
xcodegen generate
xcodebuild -project VoltPeek.xcodeproj -scheme VoltPeek -destination 'platform=macOS' test
```

### Publish this repo to GitHub

Local `git` is initialized on `main`. To create the remote (one-time):

```bash
gh auth login
gh repo create VoltPeek --public --source=. --remote=origin --push --description "Native macOS menu bar app for live battery and charging telemetry"
```

Architecture notes: [doc.md](doc.md) · Release checklist: [docs/RELEASE.md](docs/RELEASE.md) · Support: [docs/SUPPORT.md](docs/SUPPORT.md)

---

## License

MIT — see [LICENSE](LICENSE).
