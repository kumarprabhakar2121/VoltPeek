# Homebrew (future)

Primary distribution is the **Mac App Store**. Homebrew is optional for users who prefer CLI installs.

## Prerequisites

1. Apple Developer ID Application certificate + notarization (same Apple Developer Program).
2. A GitHub Release with a notarized `.dmg` or `.zip` of `VoltPeek.app`.
3. A cask formula, e.g. `Casks/voltpeek.rb`, pointing at that release URL and `sha256`.

## Suggested flow (after first notarized build)

```bash
# Example only — do not run until artifacts exist
brew install --cask voltpeek
```

Do **not** publish a cask until:

- [ ] Notarized app opens without Gatekeeper blocks
- [ ] Release assets are stable (versioned URLs)
- [ ] README install section links the cask

## Why MAS first

Better discovery and trust for a free utility; Homebrew remains a power-user complement, not a blocker.
