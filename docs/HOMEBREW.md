# Homebrew — VoltPeek

Current cask version: **1.3.0** (personal tap).

## Install (works today)

```bash
brew install --cask kumarprabhakar2121/tap/voltpeek
```

Upgrade:

```bash
brew upgrade --cask voltpeek
```

If Homebrew says the app is missing from `/Applications` (for example after Gatekeeper **Move to Trash**):

```bash
brew reinstall --cask kumarprabhakar2121/tap/voltpeek
```

Tap: https://github.com/kumarprabhakar2121/homebrew-tap

First launch may show a Gatekeeper warning (ad-hoc signed, not notarized). Steps: [README — First launch](../README.md#first-launch-macos-blocks-the-app).

## Why not plain `brew install --cask voltpeek` yet?

Official [Homebrew/homebrew-cask](https://github.com/Homebrew/homebrew-cask) will reject VoltPeek until:

1. **Apple Developer ID + notarization** — Gatekeeper signature audit currently fails (ad-hoc signed DMG).
2. **Notability** — GitHub repo needs roughly **≥75 stars** (and forks/watchers) per Homebrew’s new-cask audit.

Until then, the personal tap is the supported install path.

## Path to official Homebrew Cask

1. Enroll in [Apple Developer Program](https://developer.apple.com/programs/) (~$99/yr).
2. Sign with **Developer ID Application**, notarize, staple, rebuild DMG (`./scripts/make-dmg.sh`).
3. Publish a new GitHub Release with the notarized DMG + update SHA in the tap.
4. Grow repo stars / public presence to pass notability.
5. Fork `Homebrew/homebrew-cask`, add `Casks/v/voltpeek.rb`, run:

   ```bash
   brew audit --cask --online --new voltpeek
   brew style --fix voltpeek
   ```

6. Open a PR with title: `voltpeek 1.x.x (new cask)`.

## Update / uninstall

```bash
brew upgrade --cask voltpeek
brew uninstall --cask voltpeek
```

## Maintainers — bump a version

1. Bump `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` in `project.yml`, run `xcodegen generate`.
2. `./scripts/make-dmg.sh X.Y.Z` (match the new marketing version; prefer notarized once available).
3. Upload `VoltPeek-X.Y.Z.dmg` to GitHub Release `vX.Y.Z`.
4. Update [homebrew-tap `Casks/voltpeek.rb`](https://github.com/kumarprabhakar2121/homebrew-tap/blob/main/Casks/voltpeek.rb) `version` + `sha256`.
5. Push the tap.
