# Release checklist — Mac App Store (free)

VoltPeek is free for users ($0). You still need an **Apple Developer Program** membership to upload.

## One-time setup

1. Enroll at [developer.apple.com/programs](https://developer.apple.com/programs/) (~$99/year).
2. In [App Store Connect](https://appstoreconnect.apple.com), create app **VoltPeek**, bundle ID `com.voltpeek.app`.
3. Host privacy policy URL (this repo’s [PRIVACY.md](PRIVACY.md) via GitHub Pages, or your site).
4. Prepare screenshots (menu bar + popover List/Cards/Glass; Settings).
5. In Xcode: Signing & Capabilities → Team = your Apple ID team; enable Hardened Runtime (already on).

## Build & upload

1. Set marketing version / build in `project.yml` (`MARKETING_VERSION`, `CURRENT_PROJECT_VERSION`), run `xcodegen generate`.
2. Product → Archive (Release).
3. Distribute App → App Store Connect → Upload.
4. In App Store Connect: pricing **Free**, age rating, privacy nutrition labels (Data Not Collected), review notes.
5. Submit for Review.

## Review notes tip

Mention: menu bar–only (`LSUIElement`), local IOKit battery reads, no networking, support `hello@voltpeek.app`.

## After approval

- Tag git release `v1.0.0`
- Optionally publish notarized DMG for Homebrew (see [HOMEBREW.md](HOMEBREW.md))
