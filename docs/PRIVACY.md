# Privacy Policy — VoltPeek

**Effective date:** 2026-07-20  
**Contact:** [hello@voltpeek.app](mailto:hello@voltpeek.app)

## Summary

VoltPeek is a macOS menu bar utility that shows battery and charging information. It is **fully offline**: it processes data **on your Mac only**, does not require internet access, and does not phone home.

## Data we collect

**None.** VoltPeek does not collect personal information, analytics, advertising identifiers, or upload crash reports.

## Data the app reads locally

VoltPeek uses Apple’s IOKit / IOPowerSources APIs to read battery and charger metrics (percentage, watts, voltage, current, temperature, health, cycle count, adapter details). This data stays on your device and is not uploaded.

The app does **not** read your files, photos, contacts, messages, browsing history, or Keychain.

## Local battery history

Battery Log (Beta) stores up to 100 recent charging and battery-use sessions in an atomic JSON file under Application Support. Entries contain local timestamps, battery percentages, session type, and duration. Sleep and app-restart gaps are excluded. This history never leaves your Mac.

## Local diagnostics (optional, on-device)

VoltPeek may write diagnostic logs and crash markers under Application Support on your Mac so you can debug issues. It keeps one activity log for the current local calendar day and removes older activity logs automatically; the latest crash marker is retained until cleared. These files stay local. Nothing is uploaded automatically. You can copy or email a report yourself from **Diagnostics** if you choose to contact support.

## Accounts and networking

- No account or sign-in
- No network requests (no telemetry, ads, or analytics)
- Optional Launch at Login uses macOS Service Management on-device
- Optional top-center power-status alerts and gentle sounds are generated locally from battery state changes
- Optional support email uses your Mail app (`mailto:`) only when you tap it

## Third parties

VoltPeek does not share data with third parties. There are no third-party SDKs in the app.

## Children

The app is not directed at children and does not knowingly collect children’s data.

## Changes

We may update this policy; the effective date above will change. Continued use after updates constitutes acceptance.

## Contact

Questions: [hello@voltpeek.app](mailto:hello@voltpeek.app)
