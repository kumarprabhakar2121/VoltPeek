# Homebrew — VoltPeek

## Install (works today)

```bash
brew tap kumarprabhakar2121/tap
brew install --cask voltpeek
```

After the tap is added once, this short form works:

```bash
brew install --cask voltpeek
```

One-liner:

```bash
brew install --cask kumarprabhakar2121/tap/voltpeek
```

Tap: https://github.com/kumarprabhakar2121/homebrew-tap

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

1. `./scripts/make-dmg.sh 1.0.1` (prefer notarized once available)
2. Upload `VoltPeek-1.0.1.dmg` to GitHub Release `v1.0.1`
3. Update [homebrew-tap `Casks/voltpeek.rb`](https://github.com/kumarprabhakar2121/homebrew-tap/blob/main/Casks/voltpeek.rb) `version` + `sha256`
4. Push the tap
