# Support — VoltPeek

**Email:** [hello@voltpeek.app](mailto:hello@voltpeek.app)  
**Developer:** [Prabhakar Kumar](https://github.com/kumarprabhakar2121)  
**GitHub:** [github.com/kumarprabhakar2121](https://github.com/kumarprabhakar2121)

Hosted page: https://kumarprabhakar2121.github.io/VoltPeek/support.html

VoltPeek is a **fully offline** app. It does not need internet access and does not upload your data. See [PRIVACY.md](PRIVACY.md) and the [README](../README.md) first-launch notes if macOS blocks the app on open.

## Known limitations

- Desktop Macs without a battery show limited or unavailable fields.
- Adapter name, wattage, voltage, and current depend on what IOKit exposes for your charger.
- Time-to-full and battery-runtime estimates appear only when macOS provides them. A fully charged Mac cannot produce an accurate discharge-runtime estimate until it is unplugged.
- Very short refresh intervals (e.g. 0.5 s) use more CPU; prefer 2–3 s for everyday use.
- Menu bar Battery / Watts / Both icons follow the system menu bar appearance (light or dark).
- The top-center power-status pill uses the active window, pointer, or built-in display to choose a screen.
- GitHub / Homebrew builds are ad-hoc signed (not notarized yet). First launch may need **Open Anyway** in Privacy & Security — see the [README](../README.md).

## Manual smoke checklist (before App Review)

- [ ] App launches with a centered standalone window, Dock icon, and configured menu-bar item
- [ ] Closing the window keeps the menu-bar item active; ⌘Q and Popover → Quit exit completely
- [ ] Main window resizes cleanly across Dashboard, General, Power Graph, Diagnostics, and About
- [ ] Popover opens; Status / Power / Health / Adapter show values
- [ ] Switch themes: List, Cards, Glass
- [ ] Change Display Size Compact → Extra Large; type visibly scales
- [ ] Change menu bar style (Hidden / Battery / Watts / Both) and battery appearance (Colored / B&W); label updates
- [ ] Restore a hidden menu-bar item from the Dock app under General
- [ ] Refresh interval change takes effect within a few seconds
- [ ] Power Graph shows 10 minutes of history, statistics, axes, and hover details
- [ ] Battery Log (Beta) records charging and battery-use sessions without counting sleep or restart gaps
- [ ] Plug in, unplug, reach low battery, and fully charge: the top-center pill appears briefly with the correct state, estimate, color, and gentle sound
- [ ] General → Behavior can disable the power-status pill and its sounds
- [ ] Diagnostics can copy a report, reveal the local folder, and retain only today's activity log
- [ ] About shows version, developer credit, GitHub profile link, and support email
- [ ] Launch at Login toggle works (may need approval in System Settings)
- [ ] Reset All Settings restores defaults
- [ ] Quit from popover footer exits cleanly

## Bug reports

Include: macOS version, Mac model (Apple Silicon / Intel), VoltPeek version (**About**), steps to reproduce, a screenshot if relevant, and optionally a report from **Diagnostics → Copy Report**.
