# SanctuarySound — Virtual Audio Director

<!-- [![App Store](https://img.shields.io/badge/App_Store-Download-blue?logo=apple)](https://apps.apple.com/app/sanctuarysound) -->
[![Build](https://img.shields.io/github/actions/workflow/status/sanctuarysoundapp/sanctuarysound-ios/build.yml?branch=main)](https://github.com/sanctuarysoundapp/sanctuarysound-ios/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-iOS_17+-lightgrey?logo=apple)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.9+-orange?logo=swift)](https://swift.org)

> **Precision mixer settings for every Sunday, calculated in seconds.**

SanctuarySound is a **free, open-source** iOS app that calculates optimal mixer settings for church worship services. Enter your band composition, room acoustics, setlist, and console model — get precise gain ranges, EQ curves, compressor parameters, HPF frequencies, and fader start points tailored to your specific setup.

**No subscriptions. No paywalls. No ads. Free forever.**

Built For The Church, By The Church, Free Forever.

---

## The Problem

Church sound is run by volunteers who rotate weekly. Each one struggles with the same questions: *Where should the gain be? What HPF frequency? How do I EQ this singer? What compressor settings?*

The result: inconsistent sound, feedback, frustrated worship teams, and stressed-out volunteers.

## The Solution

Enter your service details in 60 seconds. SanctuarySound's engine analyzes everything — mic types, vocal ranges, musical keys, room acoustics, drum isolation, and your specific mixer model — then outputs actionable settings for every channel.

---

## Features

**Intelligent Mixer Recommendations**
- Gain staging with safe-zone ranges for every input
- Key-aware EQ — frequency recommendations shift based on your setlist's musical keys
- Conservative, volunteer-friendly compression settings
- High-pass filter frequencies tuned to source and room
- Fader start points adjusted by song intensity

**9 Supported Mixers**

| Mixer | Gain Range | PEQ Bands |
|---|---|---|
| Allen & Heath Avantis | 5–60 dB | 4 |
| Allen & Heath SQ Series | 5–60 dB | 4 |
| Allen & Heath dLive | 5–60 dB | 4 |
| Behringer X32 | 0–60 dB | 4 |
| Midas M32 | 0–60 dB | 4 |
| Yamaha TF Series | -6–66 dB | 4 |
| Yamaha CL/QL | -6–66 dB | 4 |
| Soundcraft Si Series | -5–58 dB | 4 |
| PreSonus StudioLive | 0–60 dB | 4 |

**SPL Monitoring**
- Real-time sound pressure level measurement using the iPhone mic
- Configurable target SPL with alert modes (Strict / Balanced / Variable)
- Haptic alerts when exceeding thresholds
- Session reports with breach logging, grades, and statistics
- Calibration with 40-130 dB reference validation

**Mixer Analysis**
- Import mixer state from Allen & Heath Director CSV exports
- Delta analysis: compare your actual settings vs. calculated ideals
- Per-channel scoring with actionable suggestions
- Live console connection via TCP/MIDI (Avantis, SQ series)

**Planning Center Online Integration**
- OAuth 2.0 import of setlists (songs, keys, BPM) directly from service plans
- Team roster import with smart position-to-channel classification
- Folder navigation with breadcrumb bar
- Drum kit templates (Basic 3-mic, Standard 5-mic, Full 7-mic, Custom)

**Audio Tools**
- 31-band 1/3-octave Real-Time Analyzer (EQ Analyzer) via vDSP FFT
- RT60 room acoustics measurement (clap-test wizard + Schroeder integration)
- Sound Engineer Q&A — 13 built-in articles across 8 categories

**Apple Watch Companion**
- Real-time SPL monitoring relayed from iPhone via WatchConnectivity
- Start/stop controls from your wrist
- Past session reports viewable on Watch
- WidgetKit complications for watch face (circular gauge, corner, rectangular)

**Detail Level Gating**
- Essentials: Gain + Fader only
- Detailed: Adds EQ + HPF
- Full: Full channel strip with compression and detailed key warnings

The engine always calculates everything — the detail level only controls what's displayed.

**Accessibility**
- Comprehensive VoiceOver support across all interactive views
- Accessibility labels, hints, and traits on buttons, data displays, and navigation

---

## Screenshots

*Coming soon — dark booth-optimized UI designed for live service use.*

---

## Getting Started

### Requirements

- iOS 17.0+ (watchOS 10.0+ for companion app)
- Xcode 16.0+
- Swift 5.9+

### Build

```bash
git clone https://github.com/sanctuarysoundapp/sanctuarysound-ios.git
cd sanctuarysound-ios
open SanctuarySound.xcodeproj
```

Select an iPhone simulator and press **Cmd+R** to build and run.

### Architecture

```
SanctuarySound/
├── Config/          # App entry point, URLs
├── Models/          # Pure value types (structs, enums) — 11 files
├── Engine/          # Stateless calculation + DSP engines — 5 files
├── Views/           # SwiftUI views (dark booth-optimized) — 23 files
├── ViewModels/      # @MainActor observable classes
├── Network/         # PCO REST client, MIDI protocol, console connection — 7 files
├── Store/           # JSON persistence + OAuth + PCO manager — 4 files
├── Audio/           # SPL measurement, EQ analysis, RT60 — 3 files
├── Shared/          # Multi-target types (iOS + Watch + Widget)
├── Connectivity/    # WatchConnectivity session management
└── Tips/            # TipKit definitions

SanctuarySoundWatch/          # watchOS companion — 7 files
SanctuarySoundWatchWidgetExt/ # WidgetKit complications
```

**Pattern:** MVVM with strict separation. Models own no logic. ViewModels own the engine. Views display state. The `SoundEngine` is pure and stateless — designed for unit testing.

**Tests:** 261 iOS unit tests + 17 Watch tests passing. Zero external dependencies.

**Dependencies:** Zero. Pure Swift, SwiftUI, AVFoundation, Accelerate, and Network frameworks.

---

## Audio Engineering

The engine implements professional audio engineering principles:

- **-18 dBFS** reference level (18 dB headroom to digital clip)
- **Subtractive EQ** — cuts before boosts, always
- **Key-aware frequency analysis** — EQ recommendations shift based on the musical key of each song
- **Mixer-specific gain models** — each console has a different internal reference level
- **Conservative compression** — ratios between 2:1 and 4:1, never limiting
- **Room acoustics modeling** — 3x3 matrix (size x surface) for RT60 estimation

See [CLAUDE.md](CLAUDE.md) for the complete engineering reference.

---

## Contributing

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

**Priority areas:**
- New mixer model support (see issue templates)
- Localization (Spanish, Portuguese for global HOW community)
- Dynamic Type support for larger text sizes
- Additional unit tests for edge cases

---

## Privacy

SanctuarySound collects **no data**. The microphone is used only for real-time SPL measurement — audio is never recorded or transmitted. All user data is stored locally on your device. See [PRIVACY.md](PRIVACY.md) for the full policy.

---

## Support This Ministry

SanctuarySound is free forever. If this app helps your worship team, consider supporting its development:

- **Church Teams:** [Donate through Victory Church AL](https://victorychurchal.churchcenter.com) (tax-deductible via 501(c)(3))
- **Developers:** [GitHub Sponsors](https://github.com/sponsors/sanctuarysoundapp)

Every contribution helps us build more tools for the church audio community.

---

## License

[MIT License](LICENSE) — free to use, modify, and distribute.

---

## Acknowledgments

Built with love for the volunteers who show up every Sunday to make church sound great. You are the unsung heroes of worship.

*Stop guessing. Start mixing.*
