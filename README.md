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
- Three styles: Battery, Watts, Both
- Battery appearance: Colored or Black & White
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
brew install --cask kumarprabhakar2121/tap/voltpeek
```

Details: [docs/HOMEBREW.md](docs/HOMEBREW.md).

### GitHub Release (DMG)

1. Download `VoltPeek-*.dmg` from [Releases](https://github.com/kumarprabhakar2121/VoltPeek/releases)
2. Open the DMG and drag **VoltPeek** to **Applications**
3. Launch from Applications (menu bar only — no Dock icon)

### First launch (macOS blocks the app)

VoltPeek is not Apple-notarized yet. On first open you may see:

> **"VoltPeek.app" Not Opened**  
> Apple could not verify "VoltPeek.app" is free of malware…

**Do not click Move to Trash.** Click **Done**, then allow it:

1. Open **System Settings** (Apple menu → System Settings)
2. Click **Privacy & Security**
3. Scroll down to the **Security** section
4. Find: *"VoltPeek.app" was blocked to protect your Mac*
5. Click **Open Anyway**
6. Enter your password / Touch ID if asked
7. Click **Open** once more

VoltPeek then appears in the menu bar (no Dock icon). After this, normal launch works.

**Faster alternative:** Finder → **Applications** → right-click **VoltPeek** → **Open** → **Open**.

**If you already clicked Move to Trash:** reinstall with:

```bash
brew reinstall --cask kumarprabhakar2121/tap/voltpeek
```

Then follow the steps above.

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

Release checklist: [docs/RELEASE.md](docs/RELEASE.md) · Support: [docs/SUPPORT.md](docs/SUPPORT.md)

---

## License

MIT — see [LICENSE](LICENSE).
