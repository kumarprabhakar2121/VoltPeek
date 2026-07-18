# VoltPeek

Native macOS menu bar app for live battery and charging telemetry — watts, current, voltage, temperature, health, cycles, and adapter details.

**Requirements:** macOS 14+ · Apple Silicon or Intel · no account, no network

Support: [hello@voltpeek.app](mailto:hello@voltpeek.app)

---

## Install

### Mac App Store (recommended)

VoltPeek is intended to be free on the Mac App Store. Publishing requires an [Apple Developer Program](https://developer.apple.com/programs/) membership (~$99/year) even when the app price is $0.

Until the Store listing is live, build from source (below).

### Build from source

```bash
brew install xcodegen   # if needed
cd /path/to/battery
xcodegen generate
open VoltPeek.xcodeproj
```

Build and run the **VoltPeek** scheme. The app appears in the menu bar only (no Dock icon).

### Homebrew

A Homebrew cask is planned after the first notarized GitHub Release. See [docs/HOMEBREW.md](docs/HOMEBREW.md).

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

VoltPeek reads battery data **locally** via IOKit. It does not collect analytics, sell data, or require sign-in. See [docs/PRIVACY.md](docs/PRIVACY.md).

---

## Development

```bash
xcodegen generate
xcodebuild -scheme VoltPeek -destination 'platform=macOS' test
```

Architecture notes: [doc.md](doc.md) · Release checklist: [docs/RELEASE.md](docs/RELEASE.md) · Support: [docs/SUPPORT.md](docs/SUPPORT.md)

---

## License

MIT — see [LICENSE](LICENSE).
