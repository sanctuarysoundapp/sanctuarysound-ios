# Contributing to SanctuarySound

Thank you for your interest in contributing to SanctuarySound! This app helps church production & worship teams get better sound every Sunday, and contributions from the community make it better for everyone.

## Getting Started

### Prerequisites

- macOS with Xcode 16.0+
- iOS 17.0+ deployment target (watchOS 10.0+ for companion)
- Swift 5.9+
- No external dependencies required

### Setup

```bash
git clone https://github.com/sanctuarysoundapp/sanctuarysound-ios.git
cd sanctuarysound-ios
open SanctuarySound.xcodeproj
```

Build and run on the iOS Simulator (iPhone 17 Pro Max recommended). The project includes an iOS app, watchOS companion, and widget extension.

## How to Contribute

### Reporting Bugs

Use the [Bug Report](https://github.com/sanctuarysoundapp/sanctuarysound-ios/issues/new?template=bug_report.md) issue template. Include:

- Steps to reproduce
- Expected vs. actual behavior
- Your device and iOS version
- Which mixer model you're using (if applicable)
- Screenshots or screen recordings

### Requesting Features

Use the [Feature Request](https://github.com/sanctuarysoundapp/sanctuarysound-ios/issues/new?template=feature_request.md) issue template. Describe:

- The use case (what problem does this solve?)
- Your proposed solution
- Which mixer models are affected (if applicable)

### Requesting New Mixer Support

Use the [Mixer Support Request](https://github.com/sanctuarysoundapp/sanctuarysound-ios/issues/new?template=mixer_support.md) template. Include:

- Mixer brand and model
- Gain range (min to max dB)
- Number of PEQ bands
- Fader range and unity position
- Any documentation links

### Branching Strategy

We use a `develop` → `main` workflow:

- **`develop`** — integration branch where all feature work lands
- **`main`** — production-quality releases only (tagged versions go to TestFlight)
- Feature branches target `develop`, not `main`

### Submitting Code

1. Fork the repository
2. Create a feature branch from `develop`: `git checkout -b feature/your-feature develop`
3. Make your changes following the code conventions below
4. Write or update tests as needed (289+ tests must pass)
5. Ensure the project builds clean with no warnings
6. Submit a pull request to `develop`

## Code Conventions

### Architecture

- **MVVM** with strict separation: Models are pure value types, ViewModels are `@MainActor` classes, Views contain zero business logic
- **SoundEngine** is stateless and pure — takes inputs, returns outputs, no side effects
- **Immutability** — create new objects, never mutate existing ones

### Swift Style

- Follow Swift API Design Guidelines
- Use `private` by default, expose only what's needed
- All audio values are `Double` (dB, Hz, seconds)
- Use `ClosedRange<Double>` for value ranges
- Industry abbreviations are acceptable: `dB`, `Hz`, `HPF`, `EQ`, `RT60`, `BPM`, `SPL`, `DI`, `FOH`

### File Organization

```swift
// MARK: - ─── Section Name ─────────────────────────────────────────────
```

Each file follows: header comment → imports → MARK sections → extensions → preview provider (views only).

### UI

- Use `BoothColors` for all colors — never hardcode
- Design for dark sound booth conditions
- Large touch targets (minimum 44pt)
- Monospaced design variant for numeric values

### Testing

- 289+ iOS unit tests and 17 Watch tests must all pass before submitting a PR
- Test pure functions with known inputs and expected output ranges
- Aim for 80%+ coverage on the Engine layer
- Use test-driven development: write tests first (RED), implement (GREEN), refactor
- Run: `xcodebuild test -scheme SanctuarySound -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max'`

## Audio Engineering Notes

If you're contributing to the `SoundEngine`:

- All gain calculations target **-18 dBFS** (industry standard nominal operating level)
- Mic sensitivity offsets are relative to SM58 (0 dB reference)
- EQ recommendations are **subtractive-first** (cuts over boosts)
- Compressor ratios stay between **2:1 and 4:1** (no limiting)
- Key-aware EQ uses semitone math: `freq = C1 * 2^(semitone/12)` where C1 = 32.703 Hz

See `CLAUDE.md` for the complete audio engineering reference.

## Sustainability

SanctuarySound is a free, open-source ministry tool. Development is supported through donations via the church's 501(c)(3) and [GitHub Sponsors](https://github.com/sponsors/sanctuarysoundapp). There are no paywalls, no premium tiers, and no feature gating. Every feature is available to every user.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
