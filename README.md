# VoltPeek

**Live battery and charging telemetry in your Mac menu bar and a full native dashboard.**

VoltPeek is a native macOS battery utility for MacBooks that surfaces the charging details macOS keeps buried — signed wattage, current, voltage, temperature, health, cycle count, and adapter info — in both a lightweight menu-bar popover and a responsive standalone app.

Built for developers and power users who want to know *how* the pack is charging, not just that it is.

**Safe & fully offline.** VoltPeek never connects to the internet, never phones home, and never reads your files, photos, messages, or accounts. It only reads battery and power info that macOS already exposes locally. Open source under MIT — you can inspect every line.

**Requirements:** macOS 14+ · Apple Silicon or Intel · no account · no network

Support: [hello@voltpeek.app](mailto:hello@voltpeek.app)

---

## What it shows

Click the menu bar item for a compact popover with:

| Section | Details |
| --- | --- |
| **Status** | Battery %, charging / on AC, time remaining |
| **Power** | Signed watts (W), current (A), voltage (V), temperature (°C) |
| **Health** | Health %, cycle count, current and max capacity (mAh) |
| **Adapter** | Connected state, name, wattage, and voltage/current/manufacturer when IOKit exposes them |

Power values are **signed**: positive while charging into the pack, negative while discharging. That makes slow chargers, USB-C PD quirks, and discharge under load obvious at a glance.

---

## Features

### Menu bar
- Four styles: Hidden, Battery, Watts, Both
- Battery appearance: Colored or Black & White
- Continues monitoring when the main window is closed; use **Quit** or ⌘Q to exit completely

### Popover look
- Themes: **List** (dense), **Cards** (grouped), **Glass** (frosted)
- Display Size: Compact → Extra Large (type and spacing scale together)
- Subtle layered surfaces and a gentle green background tint while actively charging
- Follows system Light / Dark appearance (no separate theme toggle)

### Standalone app
- Responsive Dashboard, General, Power Graph, Battery Log (Beta), Diagnostics, and About tabs
- Battery Log (Beta) records local charging and battery-use sessions while excluding sleep and app-restart gaps
- Standard Dock icon and macOS window controls
- Opens centered at 75% of the active screen's usable area
- App zoom from 80%–200% in 20% steps with crisp native rendering
- Closing the window keeps VoltPeek running in the menu bar

### Live updates
- Configurable refresh: 0.5–10 seconds (default 3 s)
- Immediate power-source change refresh with polling fallback
- Interactive 10-minute signed-wattage graph with axes, grid lines, hover details, and current/minimum/average/maximum statistics

### Power status pill
- Brief top-center alerts for charging, unplugged/on battery, low battery, and fully charged states
- Shows time to full or estimated battery runtime when macOS provides it
- Distinct high-contrast state colors and gentle low-volume sounds
- Non-activating and multi-display aware; it does not steal keyboard focus
- Visual and sound controls are available under **General → Behavior**

### Preferences
- Launch at Login
- Accessibility overrides: contrast, bold text, reduce transparency, differentiate without color
- Local Diagnostics with one current-day activity log; older activity logs are removed automatically
- Copy, email, or report diagnostics manually — nothing is uploaded automatically
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
3. Launch from Applications; VoltPeek opens its dashboard and adds the configured menu-bar item

### First launch (macOS blocks the app)

**This warning is about signing, not about malware.** VoltPeek is safe to open. It is a completely offline app: no internet access, no analytics, no account, and no access to your personal data — only local battery readings.

Apple shows this dialog because the download is not notarized yet (that needs a paid Apple Developer certificate). The message does **not** mean the app was scanned and found harmful.

On first open you may see:

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

VoltPeek then opens normally with its dashboard, Dock icon, and menu-bar item.

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

Build and run the **VoltPeek** scheme. The standalone app and menu-bar item start together.

---

## Privacy & safety

VoltPeek is designed to be trustworthy and private by default:

| | |
| --- | --- |
| **Offline** | No network calls. Works with Wi‑Fi and Ethernet off. |
| **No accounts** | Nothing to sign in to. |
| **No tracking** | No analytics, ads, telemetry, or automatic crash upload. |
| **No personal data** | Does not read your files, photos, contacts, messages, or keychain. |
| **Local only** | Battery/power info via IOKit / IOPowerSources on your Mac. |
| **Diagnostics** | Optional on-device logs; you choose whether to copy or email them. |
| **Open source** | MIT — review the code yourself. |

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
