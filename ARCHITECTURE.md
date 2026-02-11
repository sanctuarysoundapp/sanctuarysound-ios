# Architecture & Engineering Reference

> **Stack:** Swift 5.9+ / SwiftUI / MVVM / iOS 17+ / watchOS 10+
> **Dependencies:** Zero. Pure Apple frameworks — SwiftUI, AVFoundation, Accelerate, Network.
> **Tests:** 287 iOS unit + 9 UI + 17 Watch

---

## Project Structure

```
SanctuarySound/
├── Config/                  # App entry point, centralized URLs and constants
├── Models/                  # Pure value types (structs, enums) — 11 files
├── Engine/                  # Stateless calculation + DSP engines — 5 files
├── Views/                   # SwiftUI views (dark booth-optimized) — 23 files
│   └── Components/          # Reusable UI primitives
├── ViewModels/              # @MainActor observable classes
├── Network/                 # PCO REST client, MIDI protocol, console connection — 7 files
├── Store/                   # JSON persistence, OAuth, Keychain — 4 files
├── Audio/                   # SPL measurement, EQ analysis, RT60 — 3 files
├── Shared/                  # Multi-target types (iOS + Watch + Widget)
├── Connectivity/            # WatchConnectivity session management
└── Tips/                    # TipKit definitions

SanctuarySoundWatch/          # watchOS companion — 7 files
SanctuarySoundWatchWidgetExt/ # WidgetKit complications
```

### MVVM (Strict Separation)

- **Models** are pure value types (`struct`, `enum`). No business logic. No imports beyond `Foundation`.
- **ViewModels** are `@MainActor final class` using `@Published` properties. They own the engine instances.
- **Views** are SwiftUI structs. They observe ViewModels via `@StateObject` or `@ObservedObject`. Zero business logic in views.
- **SoundEngine** is pure and stateless. Takes inputs, returns outputs. No side effects. Designed for unit testing.

### Data Persistence

All user data is stored locally as JSON in the app's Documents directory. No backend, no cloud sync, no analytics. OAuth tokens for Planning Center are stored in the Keychain via `SecureStorage`.

---

## Audio Engineering Model

The calculation engine implements professional audio engineering principles. These constants define how SanctuarySound generates mixer recommendations.

### Reference Levels

| Constant | Value | Purpose |
|---|---|---|
| Digital reference level | **-18 dBFS** | Nominal operating level. Provides 18 dB headroom to digital clip (0 dBFS). |
| A4 tuning reference | **440 Hz** | Standard concert pitch for key-to-frequency conversions. |
| C1 base frequency | **32.703 Hz** | Semitone formula: `freq = C1 * 2^(semitone/12)` |

### Gain Staging Model

**Microphone sources:**
```
gain = 50 + (94 - actualSPL) + micOffset
```
Based on SM58 reference: 94 dB SPL produces -44 dBu output, requiring ~50 dB of gain to reach the -18 dBFS target (+6 dBu).

**DI / Line-level sources:**
```
gain = targetDBu - sourceLevel
```
Target is +6 dBu (-18 dBFS). DI sources typically range from -20 to +4 dBu.

**Safe zone:** ±5 dB around the calculated nominal gain. The recommended "window" is 10 dB wide.

### Mic Sensitivity Offsets

Relative to the SM58 dynamic cardioid (0 dB reference):

| Mic Type | Offset | Rationale |
|---|---|---|
| Dynamic Cardioid | 0 dB | Reference (SM58) |
| Condenser LDC | -10 dB | Hotter output, needs less gain |
| Condenser SDC | -12 dB | Even hotter than LDC |
| Ribbon | +5 dB | Lower output, needs more gain |
| Lavalier | -6 dB | Moderate sensitivity |
| Headset | -8 dB | Positioned close to source |

### EQ Philosophy

- **Subtractive-first.** Cuts before boosts, always. Boosts are used sparingly for presence/air and kept under +3 dB.
- **Key-aware frequency shifting.** The engine adjusts EQ recommendations based on the musical key of each song:
  - Kick/bass conflict: If bass fundamental overlaps kick sweet spot (50-120 Hz), a carve cut is suggested at the bass's fundamental.
  - Guitar/keys mud: If the key's 3rd harmonic lands in 150-500 Hz, a subtle cut is placed at that frequency.
  - Bass reinforcement: Boost at the key's octave-2 fundamental.
- **Deduplication.** Bands within 15% frequency proximity are merged. Output is capped at the mixer's physical EQ band count.

### Compression

Conservative by design. Ratios stay between 2:1 and 4:1. Limiting (10:1+) is never suggested — volunteers can easily create pumping artifacts with aggressive compression.

### Room Acoustics (3x3 Matrix)

| Size | Base RT60 |
|---|---|
| Small (<300 seats) | 0.8s |
| Medium (300-800) | 1.2s |
| Large (800+) | 1.8s |

| Surface | Multiplier |
|---|---|
| Absorbent | x0.6 |
| Mixed | x1.0 |
| Reflective | x1.5 |

**Effective RT60** = `baseRT60 * surfaceMultiplier`

RT60 > 1.5s triggers a "boomy room" flag with additional low-end management guidance.

---

## Mixer Support

Nine digital consoles are supported. Each is defined in the `MixerModel` enum with gain range, fader range, unity position, and EQ band count.

| Mixer | Gain Range | PEQ Bands |
|---|---|---|
| Allen & Heath Avantis | 5-60 dB | 4 |
| Allen & Heath SQ Series | 5-60 dB | 4 |
| Allen & Heath dLive | 5-60 dB | 4 |
| Behringer X32 | 0-60 dB | 4 |
| Midas M32 | 0-60 dB | 4 |
| Yamaha TF Series | -6-66 dB | 4 |
| Yamaha CL/QL | -6-66 dB | 4 |
| Soundcraft Si Series | -5-58 dB | 4 |
| PreSonus StudioLive | 0-60 dB | 4 |

Each mixer has a `referenceGainAt94SPL` value reflecting its internal reference level, so gain calculations are console-specific.

### Console Connection

Allen & Heath consoles (Avantis, SQ) support TCP/MIDI on port 51325 for live parameter reading. The app uses a read-first approach — importing current settings for delta analysis before any push operations.

---

## Detail Level System

Users choose how much information to display. The engine always computes the full channel strip; the detail level only gates what the view renders.

| Level | Gain/Fader | HPF | EQ | Compression | Key Warnings |
|---|---|---|---|---|---|
| **Essentials** | Yes | - | - | - | Simplified |
| **Detailed** | Yes | Yes | Yes | - | Yes |
| **Full** | Yes | Yes | Yes | Yes | Detailed |

This means upgrading the detail level mid-session reveals all data instantly — nothing needs to be recalculated.

---

## SPL Monitoring

### Measurement

Real-time sound pressure level via the iPhone microphone with user calibration (40-130 dB reference range). Throttled to 10 Hz UI updates via `CACurrentMediaTime()` gating.

### Alert System

- **Debounced detection:** 1.5s sustained breach to trigger, 3s clear to dismiss
- **Three alert modes:** Strict / Balanced / Variable
- **Haptic feedback** on threshold breach
- **Cross-tab banner** visible on all tabs when active
- **Session reports** auto-generated on stop: grade, statistics, breach timeline with timestamps

### Apple Watch Companion

Real-time SPL data relayed from iPhone via WatchConnectivity. Watch can start/stop monitoring and view past session reports. WidgetKit complications provide at-a-glance SPL on the watch face.

---

## Planning Center Integration

OAuth 2.0 with PKCE via `ASWebAuthenticationSession`. Imports setlists (songs, keys, BPM) and team rosters from service plans. Smart position classification filters ~30 production keywords to separate audio team members from non-audio roles.

Drum kit templates (Basic 3-mic, Standard 5-mic, Full 7-mic, Custom) auto-expand team imports into individual channels.

---

## UI / Design System

### Philosophy

Designed for use in a **dark sound booth** during live services. High contrast, no bright whites, large touch targets. Inspired by the visual language of audio hardware — fader LEDs, VU meters, clip indicators.

### Color Palette (`BoothColors`)

```
Background:       #0F0F14   near-black with slight blue warmth
Surface:          #1A1A21   card backgrounds
Surface Elevated: #242430   inputs, nested elements
Accent:           #4DC08D   green — fader LED / "safe" indicator
Accent Warm:      #F2A633   amber — VU meter, warnings
Accent Danger:    #F24D40   red — clip indicator, critical warnings
Text Primary:     #EBEBF0   high contrast on dark backgrounds
Text Secondary:   #8C8C99   labels, descriptions
Text Muted:       #59596B   disabled, tertiary info
Divider:          #2E2E38   subtle separators
```

Colors are provided through `BoothColors`, which delegates to `ThemeProvider.activeColors`. Five dark themes are available: Northern Lights, Ocean Depths, Arctic Serenity, Forest Canopy, and Volcanic Wonder. Never hardcode color values — always use `BoothColors`.

### Typography

- **Section titles:** System monospaced, bold, ALL CAPS with letter-spacing
- **Data values:** Monospaced design variant for numeric alignment
- **Body text:** System default, 13-15pt
- **Badges:** 9-11pt bold monospaced

### Component Library

| Component | Purpose |
|---|---|
| `SectionCard` | Dark card container with accent-colored section title |
| `BoothTextField` | Styled text field with label |
| `InfoBadge` | Compact metadata display (label + value) |
| `EmptyStateView` | Placeholder for empty lists |
| `ChannelRow` | Input channel list item with MIC/LINE badge |
| `SongRow` | Setlist item with key badge and BPM |
| `SummaryRow` | Key-value pair for review screens |
| `IconPicker` | Grid/row icon-based picker (replaces overflowing segmented controls) |
| `StepIndicatorBar` | Multi-step progress indicator |
| `StepNavigationBar` | Back/Next navigation footer |

---

## Code Conventions

### Swift Style

- **Naming:** Swift API design guidelines. No abbreviations except industry-standard: `dB`, `Hz`, `HPF`, `EQ`, `RT60`, `BPM`, `SPL`, `DI`, `FOH`.
- **Access control:** `private` by default. Only expose what's needed.
- **Enums:** `CaseIterable`, `Identifiable`, `Codable` where applicable. Raw values are human-readable strings.
- **IDs:** All models use `UUID` for `Identifiable` conformance.

### File Organization

```swift
// MARK: - ─── Section Name ─────────────────────────────────────────────
```

Each file follows: header comment block, imports, MARK sections grouped by functionality, extensions, preview provider (views only).

### Audio Domain Types

- dB values: `Double`
- Frequency: `Double` (Hz)
- Time: `Double` (seconds for RT60, milliseconds for attack/release)
- Ranges: `ClosedRange<Double>`
- SPL values: dB SPL unless noted as dBu or dBFS
- EQ gain: positive = boost, negative = cut
- Compressor threshold: dBFS (negative values)

---

## Testing

The engine's stateless design makes it ideal for unit testing. Test suites cover:

- **SoundEngine** — Gain, HPF, EQ, room acoustics, clamping, multi-channel
- **ForceUnwrapSafety** — Edge cases for defensive unwrapping
- **SPLCalibration** — Calibration offset math, range validation
- **SPLFormatting** — DateFormatter output correctness
- **PCOClient** — OAuth, API endpoints, folder navigation, position classification
- **WatchSPLViewModel** — Alert state, snapshot encoding

UI tests capture 9 screenshots across key app states for regression and App Store assets.

---

## Domain Glossary

| Term | Definition |
|---|---|
| **dBFS** | Decibels relative to Full Scale. 0 dBFS = digital clip point. |
| **dBu** | Decibels relative to 0.775V. Professional line level = +4 dBu. |
| **dB SPL** | Sound Pressure Level. 94 dB SPL = standard vocal reference at 1 meter. |
| **Gain Staging** | Setting preamp gain so the signal hits -18 dBFS with adequate headroom. |
| **HPF** | High-Pass Filter. Removes frequencies below a cutoff to eliminate rumble and handling noise. |
| **RT60** | Reverberation Time. Seconds for sound to decay by 60 dB. |
| **Unity Gain** | Fader position with no boost or cut (0 dB on digital consoles). |
| **FOH** | Front of House. The main speaker mix the congregation hears. |
| **DI** | Direct Input. Signal path into the console without a microphone (keyboard, bass, tracks). |
| **Proximity Effect** | Bass buildup when a directional mic is very close to the source. |
| **Q Factor** | EQ band width. Higher Q = narrower. Lower Q = wider. |
| **Headroom** | Distance between operating level and clip. At -18 dBFS, headroom = 18 dB. |
| **HOW** | House of Worship. The venue context this app serves. |

---

## License

[MIT](LICENSE) — free to use, modify, and distribute.
