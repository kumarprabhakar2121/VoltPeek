# Support — VoltPeek

**Email:** [hello@voltpeek.app](mailto:hello@voltpeek.app)

Hosted page: https://kumarprabhakar2121.github.io/VoltPeek/support.html

VoltPeek is a **fully offline** app. It does not need internet access and does not upload your data. See [PRIVACY.md](PRIVACY.md) and the [README](../README.md) first-launch notes if macOS blocks the app on open.

## Known limitations

- Desktop Macs without a battery show limited or unavailable fields.
- Adapter name, wattage, voltage, and current depend on what IOKit exposes for your charger.
- Very short refresh intervals (e.g. 0.5 s) use more CPU; prefer 2–3 s for everyday use.
- Menu bar Battery / Watts / Both icons follow the system menu bar appearance (light or dark).
- GitHub / Homebrew builds are ad-hoc signed (not notarized yet). First launch may need **Open Anyway** in Privacy & Security — see the [README](../README.md).

## Manual smoke checklist (before App Review)

- [ ] App launches to menu bar only (no Dock icon)
- [ ] Popover opens; Status / Power / Health / Adapter show values
- [ ] Switch themes: List, Cards, Glass
- [ ] Change Display Size Compact → Extra Large; type visibly scales
- [ ] Change menu bar style (Battery / Watts / Both) and battery appearance (Colored / B&W); label updates
- [ ] Refresh interval change takes effect within a few seconds
- [ ] Settings → Power Graph shows a sparkline after some samples
- [ ] Settings → Diagnostics can copy a report and reveal the local log folder
- [ ] About shows version and support email link
- [ ] Launch at Login toggle works (may need approval in System Settings)
- [ ] Reset All Settings restores defaults
- [ ] Quit from popover footer exits cleanly

## Bug reports

Include: macOS version, Mac model (Apple Silicon / Intel), VoltPeek version (**Settings → About**), steps to reproduce, a screenshot if relevant, and optionally a Diagnostics report (**Settings → Diagnostics → Copy Report**).
