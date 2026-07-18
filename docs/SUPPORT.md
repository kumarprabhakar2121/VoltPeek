# Support — VoltPeek

**Email:** [hello@voltpeek.app](mailto:hello@voltpeek.app)

## Known limitations

- Desktop Macs without a battery show limited or unavailable fields.
- Adapter name/wattage depends on what IOKit exposes for your charger.
- Very short refresh intervals (e.g. 0.5 s) use more CPU; prefer 2–3 s for everyday use.
- Menu bar emoji/text styles may look different in light vs dark menu bar appearances.

## Manual smoke checklist (before App Review)

- [ ] App launches to menu bar only (no Dock icon)
- [ ] Popover opens; Status / Power / Health / Adapter show values
- [ ] Switch themes: List, Cards, Glass
- [ ] Change Display Size Compact → Extra Large; type visibly scales
- [ ] Change menu bar style; label updates
- [ ] Refresh interval change takes effect within a few seconds
- [ ] Settings → Power Graph shows a sparkline after some samples
- [ ] About shows version and support email link
- [ ] Launch at Login toggle works (may need approval in System Settings)
- [ ] Reset All Settings restores defaults
- [ ] Quit from popover footer exits cleanly

## Bug reports

Include: macOS version, Mac model (Apple Silicon / Intel), VoltPeek version (About tab), steps to reproduce, and a screenshot if relevant.
