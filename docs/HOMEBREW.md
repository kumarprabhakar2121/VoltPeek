# Homebrew — VoltPeek

VoltPeek is published via a personal Homebrew tap (official `homebrew-cask` can follow after notarization).

## Install

```bash
brew tap kumarprabhakar2121/tap
brew install --cask voltpeek
```

One-liner:

```bash
brew install --cask kumarprabhakar2121/tap/voltpeek
```

## Update / uninstall

```bash
brew upgrade --cask voltpeek
brew uninstall --cask voltpeek
```

## Gatekeeper

v1.0.0 is **ad-hoc signed** (not Apple notarized). First launch: right-click → **Open**, or allow in System Settings → Privacy & Security.

## Maintainers — bump a version

1. Build DMG: `./scripts/make-dmg.sh 1.0.1`
2. Upload to GitHub Release `v1.0.1` as `VoltPeek-1.0.1.dmg`
3. Update [`homebrew-tap/Casks/voltpeek.rb`](https://github.com/kumarprabhakar2121/homebrew-tap/blob/main/Casks/voltpeek.rb):
   - `version`
   - `sha256` (`shasum -a 256 VoltPeek-1.0.1.dmg`)
4. Commit & push the tap repo

Tap repo: https://github.com/kumarprabhakar2121/homebrew-tap

## Official Homebrew Cask (later)

After Developer ID + notarization, open a PR to [Homebrew/homebrew-cask](https://github.com/Homebrew/homebrew-cask) so users can run `brew install --cask voltpeek` without tapping.
