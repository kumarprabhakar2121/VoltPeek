# Release checklist — Mac App Store (free)

VoltPeek is free for users ($0). You still need an **Apple Developer Program** membership to upload.

## One-time setup

1. Enroll at [developer.apple.com/programs](https://developer.apple.com/programs/) (~$99/year).
2. In [App Store Connect](https://appstoreconnect.apple.com), create app **VoltPeek**, bundle ID `com.voltpeek.app`.
3. **Privacy URL** (required): `https://kumarprabhakar2121.github.io/VoltPeek/privacy.html`  
   Source: [PRIVACY.md](PRIVACY.md) → hosted page [privacy.html](privacy.html).  
   **Support URL:** `https://kumarprabhakar2121.github.io/VoltPeek/support.html`  
   Enable GitHub Pages once: repo **Settings → Pages → Deploy from a branch → `main` / `/docs`**.
4. Prepare screenshots of the Dashboard, General settings, Power Graph, Battery Log (Beta), top-center power-status pill, menu bar, and List/Cards/Glass popovers.
5. In Xcode: Signing & Capabilities → Team = your Apple ID team; enable Hardened Runtime (already on).

## Build & upload

1. Set marketing version / build in `project.yml` (`MARKETING_VERSION`, `CURRENT_PROJECT_VERSION`), run `xcodegen generate`.
2. Product → Archive (Release).
3. Distribute App → App Store Connect → Upload.
4. In App Store Connect: pricing **Free**, age rating, privacy nutrition labels (**Data Not Collected**), Privacy Policy URL and Support URL (above), review notes.
5. Submit for Review.

## App Store Connect fields (copy/paste)

| Field | Value |
|-------|--------|
| Privacy Policy URL | `https://kumarprabhakar2121.github.io/VoltPeek/privacy.html` |
| Support URL | `https://kumarprabhakar2121.github.io/VoltPeek/support.html` |
| Support Email | `hello@voltpeek.app` |
| Price | Free ($0) |
| Privacy nutrition | Data Not Collected |
| Bundle ID | `com.voltpeek.app` |

## Review notes tip

Mention: standard macOS app with a companion menu-bar item; closing the main window leaves menu-bar monitoring active while Quit/⌘Q exits completely; local IOKit battery reads only; fully offline (no networking/telemetry); local power-status pill and sounds; optional on-device Diagnostics the user can explicitly share; support `hello@voltpeek.app`.

Before submission, complete the smoke checklist in [SUPPORT.md](SUPPORT.md), including background lifecycle, all popover themes, the 10-minute graph, daily diagnostic-log rotation, and charging/unplugged/low-battery/fully-charged pill states.

## Current project versions

Check `project.yml`: `MARKETING_VERSION` (e.g. `1.1.0`) and `CURRENT_PROJECT_VERSION` (build number) before archiving.

## After approval

- Tag git release (e.g. `v1.1.0`)
- Optionally publish notarized DMG for Homebrew (see [HOMEBREW.md](HOMEBREW.md))
