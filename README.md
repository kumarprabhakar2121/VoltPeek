# VoltPeek

**Live battery and charging telemetry in your Mac menu bar.**

VoltPeek is a native macOS menu bar app for MacBooks that surfaces the charging details macOS keeps buried — signed wattage, current, voltage, temperature, health, cycle count, and adapter info — updating every few seconds with almost no resource cost.

Built for developers and power users who want to know *how* the pack is charging, not just that it is.

**Requirements:** macOS 14+ · Apple Silicon or Intel · no account, no network

Support: [hello@voltpeek.app](mailto:hello@voltpeek.app)

---

## What it shows

Click the menu bar item for a compact popover with:

| Section | Details |
| --- | --- |
| **Status** | Battery %, charging / on AC, time remaining |
| **Power** | Signed watts (W), current (A), voltage (V), temperature (°C) |
| **Health** | Cycle count, max capacity, design capacity, health % |
| **Adapter** | Connected state, adapter wattage, adapter name (when IOKit exposes them) |

Power values are **signed**: positive while charging into the pack, negative while discharging. That makes slow chargers, USB-C PD quirks, and discharge under load obvious at a glance.

---

## Features

### Menu bar
- Six styles: Text, Battery, Battery + %, Power bolt, Bolt + Watts, Battery (auto bolt)
- Text mode can show watts, percentage, or both
- Menu-bar-only app — no Dock icon

### Popover look
- Themes: **List** (dense), **Cards** (grouped), **Glass** (frosted)
- Display Size: Compact → Extra Large (type and spacing scale together)
- Light and Dark Mode

### Live updates
- Configurable refresh: 0.5–10 seconds (default 3 s)
- Power Graph tab with a short wattage sparkline (~60 s)

### Preferences
- Launch at Login
- Accessibility overrides: contrast, bold text, reduce transparency, differentiate without color
- Reset All Settings

---

## Install

### Homebrew

```bash
brew tap kumarprabhakar2121/tap
brew install --cask voltpeek
```

After tapping once, `brew install --cask voltpeek` is enough.

Official Homebrew Cask (no tap) needs Apple notarization + repo notability — see [docs/HOMEBREW.md](docs/HOMEBREW.md). First launch may need right-click → **Open** until notarized.

### Mac App Store

Planned as a free listing (requires Apple Developer Program). See [docs/RELEASE.md](docs/RELEASE.md).

### Build from source

```bash
brew install xcodegen   # if needed
cd /path/to/VoltPeek
xcodegen generate
open VoltPeek.xcodeproj
```

Build and run the **VoltPeek** scheme. The app appears in the menu bar only.

---

## Privacy

VoltPeek reads battery data **locally** via IOKit / IOPowerSources. It does not collect analytics, sell data, or require sign-in.

- Policy: [docs/PRIVACY.md](docs/PRIVACY.md)
- **App Store Privacy URL:** https://kumarprabhakar2121.github.io/VoltPeek/privacy.html
- Support page: https://kumarprabhakar2121.github.io/VoltPeek/support.html

---

## Development

```bash
xcodegen generate
xcodebuild -project VoltPeek.xcodeproj -scheme VoltPeek -destination 'platform=macOS' test
```

Stack: Swift · SwiftUI · AppKit (menu bar) · IOKit · MVVM · no third-party dependencies.

Architecture notes: [doc.md](doc.md) · Release checklist: [docs/RELEASE.md](docs/RELEASE.md) · Support: [docs/SUPPORT.md](docs/SUPPORT.md)

---

## License

MIT — see [LICENSE](LICENSE).
