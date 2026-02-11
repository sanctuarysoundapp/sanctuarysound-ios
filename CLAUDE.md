# CLAUDE.md — SanctuarySound Project Bible

> **Last Updated:** 2026-02-11
> **Status:** Beta Ready — TestFlight Provisioning
> **Primary Stack:** Swift 5.9+ / SwiftUI / MVVM / iOS 17+ / watchOS 10+

---

## 🎯 What Is SanctuarySound?

SanctuarySound is a native iOS app that acts as a **"Virtual Audio Director"** for church production & worship teams. It takes complex variables (band composition, room acoustics, vocal profiles, setlist keys, mixer model) and outputs **precise, actionable mixer settings** — gain ranges, EQ curves, compressor parameters, HPF frequencies, and fader start-points — tailored to a specific Sunday service.

**The core problem:** Church sound is run by volunteers who rotate weekly. They struggle with gain staging (too low = hiss, too high = distortion), EQ decisions, and adapting to changing variables (different singers, songs, room conditions). This app calculates the optimal "safe zone" so they start each service with a solid foundation instead of guessing.

---

## 🏗️ Architecture

```
SanctuarySound/
├── Config/
│   ├── SanctuarySoundApp.swift          # @main entry point (TipKit configured)
│   └── AppConfig.swift                  # Centralized URLs, version, mission constants
├── Models/
│   ├── ServiceModels.swift              # Core enums/structs (~780 lines after Sprint B split)
│   ├── AudioConstants.swift             # Audio engineering constants (extracted Sprint B)
│   ├── MixerModel.swift                 # Mixer enum + specs (extracted Sprint B)
│   ├── VocalModels.swift                # Vocal types, profiles, ranges (extracted Sprint B)
│   ├── RecommendationModels.swift       # Engine output types (extracted Sprint B)
│   ├── AnalysisModels.swift             # Delta analysis types (extracted Sprint B)
│   ├── SPLReportFormatting.swift        # Report formatting + static DateFormatters
│   ├── UserPreferences.swift            # Defaults, ColorThemeID
│   ├── ColorTheme.swift                 # 5 dark themes
│   ├── VenueModels.swift                # Venue + Room (2-level hierarchy)
│   └── ConsoleProfile.swift             # ConsoleProfile + ConsoleConnectionType
├── Engine/
│   ├── SoundEngine.swift                # Stateless recommendation engine
│   ├── AnalysisEngine.swift             # Delta analysis (actual vs ideal)
│   ├── CSVImporter.swift                # Avantis Director CSV parser
│   ├── FrequencyAnalysis.swift          # FFTProcessor, FrequencyBands, PeakHoldTracker
│   └── RT60Calculator.swift             # RT60 measurement + Schroeder integration
├── Views/
│   ├── HomeView.swift                   # 5-tab shell + SPLAlertBanner + CSVImportSheet
│   ├── ServicesView.swift               # Services tab — saved services + venues
│   ├── InputLibraryView.swift           # Inputs tab — saved inputs + vocal profiles
│   ├── ConsolesView.swift               # Consoles tab — profiles + snapshots
│   ├── ToolsView.swift                  # Tools tab — SPL, EQ, RT60, Q&A
│   ├── SettingsView.swift               # Settings tab — prefs, theme, about
│   ├── InputEntryView.swift             # Service setup wizard (4-step) + BoothColors
│   ├── RecommendationDetailView.swift   # Engine output display (gain, EQ, comp, key warnings)
│   ├── AnalysisView.swift               # Delta analysis display
│   ├── SPLCalibrationView.swift         # SPL monitor + calibration + alerting
│   ├── SPLSessionReportView.swift       # SPL session report detail (extracted Sprint B)
│   ├── SPLReportExportView.swift        # Report sharing/export (extracted Sprint B)
│   ├── EQAnalyzerView.swift             # 31-band RTA display
│   ├── RT60MeasurementView.swift        # RT60 clap-test wizard
│   ├── QABrowserView.swift              # Sound engineer Q&A browser
│   ├── MixerConnectionView.swift        # TCP/MIDI console connection
│   ├── PCOImportSheet.swift             # Planning Center folder nav + import
│   ├── PCOTeamImportPreviewView.swift   # Team import editable checklist
│   ├── DrumKitTemplatePicker.swift       # Drum kit template picker
│   ├── AboutView.swift                  # Mission, donation links, community, legal
│   ├── OnboardingView.swift             # 5-screen welcome + Quick Setup
│   ├── SplashView.swift                 # Animated launch + RootView
│   └── Components/
│       ├── SharedComponents.swift       # SectionCard, BoothTextField, InfoBadge, etc.
│       └── StepNavigation.swift         # StepIndicatorBar, StepNavigationBar
├── ViewModels/
│   ├── ServiceSetupViewModel.swift      # Service wizard state (extracted Sprint B)
│   └── ThemeProvider.swift              # Theme switching + nonisolated storage
├── Network/
│   ├── PCOClient.swift                  # PCO REST client + OAuth
│   ├── PCOModels.swift                  # Codable PCO response structs
│   ├── MIDIMessageTypes.swift           # MIDI protocol types
│   ├── MIDIProtocol.swift               # MIDI encode/decode
│   ├── AvantisMIDIProfile.swift         # Avantis-specific MIDI params
│   ├── SQMIDIProfile.swift              # SQ-specific MIDI params
│   └── MixerConnectionManager.swift     # NWConnection lifecycle
├── Store/
│   ├── ServiceStore.swift               # JSON persistence + CRUD + migration
│   ├── SecureStorage.swift              # Keychain wrapper for OAuth tokens
│   ├── PlanningCenterManager.swift      # PCO OAuth + import operations
│   └── QAStore.swift                    # Q&A article storage
├── Audio/
│   ├── SPLMeter.swift                   # iPhone mic SPL + 10Hz throttle + OSLog
│   ├── EQAnalyzer.swift                 # Real-time EQ analysis
│   └── RT60Analyzer.swift               # RT60 measurement engine
├── Shared/                              # Multi-target: iOS + Watch + Widget
│   ├── SPLSharedTypes.swift             # SPL types shared across targets
│   └── WatchConnectivityDTO.swift       # WCSession DTOs
├── Connectivity/
│   └── WatchSessionManager.swift        # iPhone-side WCSession delegate
├── Tips/
│   └── AppTips.swift                    # TipKit definitions
├── AppLogger.swift                      # OSLog centralized logging (5 categories)
└── Resources/
    └── Assets.xcassets                  # Colors, icons

SanctuarySoundWatch/                     # watchOS companion app
├── SanctuarySoundWatchApp.swift
├── WatchSPLView.swift                   # SPL display + controls
├── WatchSPLViewModel.swift              # Watch view model
├── WatchSessionReceiver.swift           # Watch-side WCSession
├── WatchColors.swift                    # Watch theme colors
├── WatchReportsListView.swift           # Past report list
└── WatchReportDetailView.swift          # Report detail

SanctuarySoundWatchWidgetExt/
└── WatchComplicationProvider.swift      # WidgetKit complications
```

### Pattern: MVVM (Strict)
- **Models** are pure value types (`struct`, `enum`). No business logic. No imports beyond `Foundation`.
- **ViewModels** are `@MainActor final class` using `@Published` properties. They own the `SoundEngine` instance.
- **Views** are SwiftUI structs. They observe ViewModels via `@StateObject` or `@ObservedObject`. Zero business logic in views.
- **SoundEngine** is a pure, stateless class. Takes inputs, returns outputs. No side effects. Designed for unit testing.

---

## 🔊 Audio Engineering Constants & Decisions

These are **locked decisions** from the Socratic planning phase. Do not change without explicit discussion.

| Decision | Value | Rationale |
|---|---|---|
| **Digital Reference Level** | **-18 dBFS** | Industry standard nominal operating level. All gain calculations target this. Provides 18 dB headroom to 0 dBFS (digital clip). |
| **A4 Tuning Reference** | **440 Hz** | Standard concert pitch. Used for all key-to-frequency conversions. |
| **Key Math** | C1 = 32.703 Hz | Semitone formula: `freq = C1 × 2^(semitone/12)`. Harmonics: `f × n` for nth harmonic. |
| **Gain Model (Mic)** | `gain = 50 + (94 - actualSPL) + micOffset` | Based on SM58 reference: 94 dB SPL → -44 dBu output → needs ~50 dB gain to reach -18 dBFS (+6 dBu). |
| **Gain Model (DI/Line)** | `gain = targetDBu - sourceLevel` | Target +6 dBu (-18 dBFS). DI sources range from -20 to +4 dBu typically. |
| **Safe Zone** | ±5 dB around nominal | The recommended gain "window" is 10 dB wide, centered on the calculated optimal point. |

### Mic Sensitivity Offsets (relative to SM58 = 0 dB)
- Dynamic Cardioid: `0 dB` (reference)
- Condenser LDC: `-10 dB` (hotter output, needs less gain)
- Condenser SDC: `-12 dB`
- Ribbon: `+5 dB` (lower output, needs more gain)
- Lavalier: `-6 dB`
- Headset: `-8 dB`

### Room Acoustics Model (3×3 Intermediate Matrix)
- **Sizes:** Small (<300 seats, 0.8s base RT60), Medium (300-800, 1.2s), Large (800+, 1.8s)
- **Surfaces:** Absorbent (×0.6 RT60), Mixed (×1.0), Reflective (×1.5)
- **Effective RT60** = `baseRT60 × surfaceMultiplier`
- **"Boomy Room" threshold:** RT60 > 1.5s triggers additional low-end management advice

### Key-Aware EQ (Option B — Full Frequency Shifting)
The engine doesn't just warn about key conflicts — it **adjusts actual EQ recommendations** based on musical key:
- Kick/Bass conflict: If bass fundamental overlaps kick sweet spot (50-120 Hz), suggest a carve cut on the kick at the bass's fundamental frequency
- Guitar/Keys mud: If the key's 3rd harmonic lands in 150-500 Hz, suggest a subtle cut at that exact frequency
- Bass reinforcement: Boost the bass guitar at the key's octave-2 fundamental

---

## 🎛️ Mixer Support (Priority Order)

1. **Allen & Heath Avantis** — Primary target. John's console. Gain 5-60 dB, 4 PEQ, DEEP via dPack.
2. **Allen & Heath SQ Series** — Secondary A&H platform.
3. **Allen & Heath dLive** — Shares XCVI engine with Avantis.
4. **Behringer X32 / Midas M32** — Most common HOW board globally.
5. **Yamaha TF / CL/QL** — Note: gain range starts at -6 dB (not 0).
6. **Soundcraft Si** — Gain range -5 to 58 dB.
7. **PreSonus StudioLive** — Standard ranges.

Each mixer is defined in the `MixerModel` enum with: gain range, fader range, unity position, EQ band count, and short display name. When adding a new mixer, update all computed properties.

### John's Band Configuration (Confirmed)
- **6 Vocalists:** 4 Female, 2 Male (SM58 dynamic mics assumed)
- **Digital Keyboard:** Stereo DI (2 channels — L/R)
- **2 Electric Guitars:** Amp modelers / DI
- **1 Acoustic Guitar:** DI / pickup
- **1 Bass Guitar:** DI
- **Full Drum Kit with Cage:** Kick, snare, hi-hat, 3 toms, 2 overheads
- **Total Channel Count:** ~20 channels
- **Target SPL:** ~90 dB max at mix position during full worship

---

## 👤 Detail Level System (Configurable Depth)

The user selects their detail level, which gates what recommendations are shown:

| Level | Gain/Fader | HPF | EQ | Compression | Key Warnings |
|---|---|---|---|---|---|
| **Essentials** | ✅ | ❌ | ❌ | ❌ | ✅ (simplified) |
| **Detailed** | ✅ | ✅ | ✅ | ❌ | ✅ |
| **Full** | ✅ | ✅ | ✅ | ✅ | ✅ (detailed) |

The engine **always calculates everything** — the detail level only controls what the View displays. This means if a user upgrades their level mid-session, all data is already computed.

---

## 🎨 UI / Design System

### Philosophy
Designed for use in a **dark sound booth** during live services. High contrast, no bright whites, large touch targets.

### Color Palette (`BoothColors`)
```
Background:       #0F0F14   (near-black with slight blue warmth)
Surface:          #1A1A21   (card backgrounds)
Surface Elevated: #242430   (inputs, nested elements)
Accent:           #4DC08D   (green — like fader LED / "safe" indicator)
Accent Warm:      #F2A633   (amber — like analog VU meter, used for warnings)
Accent Danger:    #F24D40   (red — clip indicator, critical warnings)
Text Primary:     #EBEBF0   (high contrast on dark backgrounds)
Text Secondary:   #8C8C99   (labels, descriptions)
Text Muted:       #59596B   (disabled, tertiary info)
Divider:          #2E2E38   (subtle separators)
```

### Typography
- **Headers/Labels:** System font, monospaced design variant, `.bold`, ALL CAPS with letter-spacing for section titles
- **Values/Data:** Monospaced design variant (ensures numeric alignment)
- **Body text:** System default at 13-15pt
- **Badges:** 9-11pt bold monospaced

### Component Library (Existing)
- `SectionCard` — Dark card container with accent-colored title
- `BoothTextField` — Styled text field with label
- `InfoBadge` — Compact metadata display (label + value)
- `EmptyStateView` — Placeholder for empty lists
- `ChannelRow` — Input channel list item with MIC/LINE badge
- `SongRow` — Setlist item with key badge and BPM
- `SummaryRow` — Key-value pair for review screen
- `StepIndicatorBar` — Progress indicator with step icons
- `StepNavigationBar` — Back/Next navigation footer

---

## 📐 Code Conventions

### Swift Style
- **Naming:** Swift API design guidelines. Descriptive names. No abbreviations except industry-standard (`dB`, `Hz`, `HPF`, `EQ`, `RT60`, `BPM`, `SPL`, `DI`, `FOH`).
- **Access control:** Use `private` by default. Only expose what's needed.
- **Comments:** MARK sections with the `─── Title ───` decorative style for visual scanning.
- **Enums:** Always `CaseIterable`, `Identifiable`, `Codable` where applicable. Raw values should be human-readable display strings.
- **IDs:** All models use `UUID` for `Identifiable` conformance. Generated at init time.

### File Organization Pattern
```swift
// MARK: - ─── Section Name ─────────────────────────────────────────────
```

Each file follows:
1. File header comment block (name, purpose, architecture layer)
2. Imports
3. MARK sections grouped by functionality
4. Extensions at bottom
5. Preview provider at very bottom (Views only)

### Audio Domain Conventions
- All dB values are `Double`
- Frequency values are `Double` (Hz)
- Time values are `Double` (seconds for RT60, milliseconds for attack/release)
- Ranges use `ClosedRange<Double>`
- SPL values assume dB SPL unless noted as dBu or dBFS
- EQ gain is positive for boost, negative for cut
- Compressor threshold is in dBFS (negative values)

---

## 🧪 Testing Strategy

### ✅ 261 iOS Unit Tests Passing + 17 Watch Tests
The engine is pure and stateless — perfect for unit testing. Sprint C added comprehensive test coverage.

**Test Suites:**
- `SoundEngineTests` (8 tests) — Gain, HPF, EQ, room acoustics, clamping, multi-channel
- `ForceUnwrapSafetyTests` (10 tests) — Edge cases for all formerly force-unwrapped sites
- `SPLCalibrationTests` (5 tests) — Calibration offset math, range validation (40-130 dB)
- `SPLFormattingTests` (8 tests) — DateFormatter output correctness, idempotency
- `PCOClientTests` (90+ tests) — OAuth, API endpoints, folder nav, position classification
- `WatchSPLViewModelTests` (17 tests) — SPLAlertStateCodable, SPLSnapshot

### Snapshot Tests (Priority 2 — Planned)
- InputEntryView in each step state
- AddChannelSheet with vocal profile visible
- Dark mode rendering verification

---

## 🗺️ Roadmap

### ✅ Completed (Foundation Phase)
- [x] `ServiceModels.swift` — Full data model layer
- [x] `SoundEngine.swift` — Calculation engine with gain, EQ, compression, key-aware logic
- [x] `InputEntryView.swift` — 4-step service setup wizard
- [x] `CLAUDE.md` — Project documentation

### ✅ Completed (Sprint 1a — MVP Build)
- [x] Xcode project setup and first build (iOS 17+ deployment, Swift 5 compat mode)
- [x] `SanctuarySoundApp.swift` — App entry point
- [x] `RecommendationDetailView.swift` — Channel cards with gain, fader, HPF, EQ, compression, key warnings
- [x] Allen & Heath Avantis added to `MixerModel` (gain 5-60 dB, 4 PEQ bands)
- [x] Avantis set as default mixer
- [x] Generate button → recommendation sheet navigation wired
- [x] Engine validated against real service data (Feb 8 setlist)
- [x] Builds and runs on iPhone 17 Pro Max simulator (iOS 26.2)

### ✅ Completed (Sprint 1b — Polish & Persist)
- [x] `ServiceStore.swift` — JSON-based persistence (Documents dir, SwiftData deferred to v2)
- [x] Saved Vocalist Profiles — reusable across services, auto-saved on recommendation
- [x] Saved Input Library — universal channel presets (vocal, instrument, DI, playback)
- [x] Saved Data tab with delete/management for all saved items
- [x] Mixer-specific gain model (`referenceGainAt94SPL` per mixer, Avantis=22 dB)
- [x] UI fixes: SPL slider/stepper (70-100 dB), BPM slider/stepper (40-200), vocal range grid, visible action buttons
- [x] EQ redesign: VStack layout, CUT/BOOST badges, gain bars with dB units, readable reasons
- [x] Compressor redesign: 2x2 grid, full labels, larger fonts
- [ ] Visual fader graphic component (vertical fader with dB scale and recommended zone)
- [ ] Visual EQ curve component (frequency response graph)
- [ ] Code signing and physical device deployment

### ✅ Completed (Sprint 2 — Mixer Integration & Analysis)
- [x] CSV import from Avantis Director — parse channel names, gain, EQ, comp settings
- [x] Delta Analysis View — compare imported actuals vs computed ideals per channel
- [x] SPL ceiling model — target SPL preference with flagging modes (Strict/Balanced/Variable)
- [x] iPhone mic SPL calibration (measure at mix position, establish dBFS-to-SPL offset)
- [x] Unit test suite for `SoundEngine` — 8 tests covering gain, HPF, EQ, room acoustics, clamping
- [ ] "Quick Setup" templates (e.g., "Standard 5-piece band" pre-fills 12 channels)

### ✅ Completed (Sprint 2b — SPL Alerting & Reporting)
- [x] SPL alert state engine with debounced threshold detection (1.5s breach, 3s clear)
- [x] Haptic feedback via `.sensoryFeedback(.warning)` on threshold breach
- [x] Visual pulse animation — red border + opacity pulse on current dB readout
- [x] Cross-tab alert banner — persistent red/amber banner visible on ALL tabs when over target
- [x] SPL breach event logging — every threshold crossing recorded with timestamp, peak, duration
- [x] SPL Session Report — auto-generated on Stop with grade, stats, breach timeline
- [x] Past reports list in SPL tab — tap to review any previous session
- [x] Report persistence via ServiceStore (JSON)
- [x] Alert Mode labeling improvements ("Alert Mode" not "Flagging Mode")
- [x] SPL Preferences on Saved tab — tappable rows that navigate to SPL tab

### ✅ Completed (GTM — Open Source + Donation Model)
- [x] IAP removed — `PurchaseManager.swift` and `PaywallView.swift` deleted
- [x] All features unlocked (no gating) — free and open-source forever
- [x] `AppConfig.swift` — centralized URLs, donation via Church Center (Victory Church AL)
- [x] `AboutView.swift` — mission statement, donation links, GitHub, privacy, share
- [x] `OnboardingView.swift` — screen 1 updated for ministry mission messaging
- [x] `SplashView.swift` — animated splash screen with equalizer bars
- [x] `.github/FUNDING.yml` — GitHub Sponsors + donation link
- [x] Donation model: church 501(c)(3) routed, tax-deductible for donors
- [x] Repo foundation: .gitignore, LICENSE (MIT), README.md, PRIVACY.md, CONTRIBUTING.md
- [x] GitHub Actions CI (.github/workflows/build.yml)
- [x] Issue templates + PR template
- [x] SoundEngineTests — 8 core tests passing, test target in Xcode project
- [x] SoundEngine bug fix: gain clamping crash when drum cage isolation inverts range bounds

### 🚀 Beta Readiness (Closed Beta — TestFlight)
**Status:** READY — 0 blocking issues
- [x] Code signing configured (Automatic, Team M2739G49TS)
- [x] Info.plist has `NSMicrophoneUsageDescription` for SPL feature
- [x] All features implemented and functional through Sprint 4 + Tech Debt
- [x] 261/261 iOS unit tests passing + 17 Watch tests
- [x] BUILD SUCCEEDED (zero errors, zero warnings)
- [x] Zero IAP remnants in codebase (verified via grep)
- [x] Accessibility labels for key interactive elements (VoiceOver) — Sprint C
- [x] Technical debt remediated (3 sprints: force unwraps, file splitting, accessibility)
- [x] True data clear — "Clear All Data" fully empties store, resets onboarding (PR #15)
- [x] Test target deployment mismatch fixed — all 261 tests compile and pass (PR #15)
- [x] CI modernized — macos-26, Xcode 26.2, iPhone 17 Pro Max (PR #15)
- [x] `PrivacyInfo.xcprivacy` — Apple privacy manifest for App Store (PR #15)
- [ ] TestFlight upload and internal testing
- [ ] README screenshots (currently placeholder)

### ✅ Completed (Sprint 3 — Tools & Console Read)
- [x] EQ Analyzer — 31-band 1/3-octave RTA via Accelerate/vDSP FFT, peak hold, snapshots
- [x] Room Acoustics — RT60 clap-test wizard, Schroeder integration, room classification
- [x] Sound Engineer Q&A — 13 built-in articles, 8 categories, offline, searchable
- [x] Console Read Integration — "Connect Live" on TCP consoles, pre-fill from ConsoleProfile
- [x] `MixerConnectionView.swift` — IP entry, status, console connection
- [x] `MIDIProtocol.swift` — Encode/decode A&H MIDI TCP messages
- [x] `MixerConnectionManager.swift` — NWConnection lifecycle, reconnect, status

### ✅ Completed (Sprint 4 — Planning Center Online Integration)
- [x] `PCOClient.swift` — REST client with OAuth 2.0 + PKCE
- [x] `PCOModels.swift` — Codable PCO response structs
- [x] `PlanningCenterManager.swift` — OAuth state, sync, import operations
- [x] `PCOImportSheet.swift` — Folder navigation + service plan picker
- [x] `PCOTeamImportPreviewView.swift` — Editable team import checklist
- [x] `DrumKitTemplatePicker.swift` — Basic 3/Standard 5/Full 7/Custom drum templates
- [x] Smart position classification (~30 production keywords filtered)
- [x] Full Service Mode — combined songs + team import in one flow
- [x] Service pre-fill from PCO plan (date, name, venue auto-match)

### ✅ Completed (watchOS Companion App)
- [x] `SanctuarySoundWatch/` — 7 Swift files, real-time SPL from iPhone via WatchConnectivity
- [x] Watch can send start/stop commands back to iPhone
- [x] WidgetKit complications (circular gauge, corner text, rectangular)
- [x] Past session reports viewable on Watch
- [x] Theme-synced colors via @AppStorage

### ✅ Completed (Tech Debt Remediation — 3 Sprints)
**Sprint A (PR #12):** Force unwrap safety + error observability
- [x] 12 force unwraps eliminated across 5 files (guard-let with descriptive errors)
- [x] `AppLogger.swift` — OSLog infrastructure with 5 category-based Loggers
- [x] SPLMeter 50Hz→10Hz UI throttle via `CACurrentMediaTime()` gating
- [x] `PCOError.invalidURL(String)` — dedicated error for URL construction failures
- [x] 10 new tests in `ForceUnwrapSafetyTests.swift`

**Sprint B (PR #13):** File splitting
- [x] `ServiceModels.swift` 1,518→783 lines (5 extracted: AudioConstants, MixerModel, VocalModels, RecommendationModels, AnalysisModels)
- [x] `InputEntryView.swift` 1,652→1,007 lines (3 extracted: ServiceSetupViewModel, SharedComponents, StepNavigation)
- [x] `SPLCalibrationView.swift` 1,217→621 lines (3 extracted: SPLSessionReportView, SPLReportExportView, SPLReportFormatting)

**Sprint C (PR #14):** Accessibility + validation + performance
- [x] VoiceOver accessibility labels across 12 view files
- [x] SPL calibration input validation (40-130 dB range with error alert)
- [x] Static DateFormatters in 3 files (SPLReportFormatting, SPLCalibrationView, ToolsView)
- [x] 13 new tests (SPLCalibrationTests + SPLFormattingTests)

### 📋 Future — Live Mixer Push
**Phase 2: Push Individual Settings**
- [ ] `Network/MixerBridge.swift` — Convert recommendations → MIDI commands
- [ ] "Send to Mixer" per-channel button with confirmation flow
- [ ] Running status optimization for batch messages

**Phase 3: Scene Recall + Batch Push**
- [ ] Scene recall via MIDI Program Change
- [ ] "Send All Recommendations" batch operation
- [ ] Avantis layer/bank mapping

**Phase 4: Live Delta Analysis**
- [ ] Feed real-time MixerSnapshot into existing AnalysisEngine.analyze()
- [ ] `Views/LiveDeltaView.swift` — Color-coded live overlay (green/amber/red)

**Phase 5: VSC Workflow Support**
- [ ] Detect Virtual Sound Check mode, display "VSC Active" badge
- [ ] Per-song SPL snapshots during VSC playback
- [ ] Export recommendations as PDF or shareable image

### 🔮 Future (v2+)
- [ ] Watch-independent SPL measurement (Apple Watch mic)
- [ ] Live Activity on Lock Screen — Dynamic Island real-time SPL display
- [ ] Multi-point SPL measurement (mix position + congregation areas)
- [ ] Multi-service comparison ("Last week vs this week" using session reports)
- [ ] Community-shared room profiles and vocal profiles
- [ ] Setlist reordering (drag-and-drop)
- [ ] X32/M32 deep TCP protocol support (different protocol from A&H)
- [ ] Vocalist profile linking to PCO people records

---

## 🔌 Avantis Integration Architecture

### Locked Decisions (from Socratic Phase 2 + Sprint 3/4 Planning)

| Decision | Value | Rationale |
|---|---|---|
| **Import Method (MVP)** | CSV export from Director | Lowest friction, works offline, documented format |
| **Import Method (v2)** | TCP/MIDI on port 51325 | Real-time, documented by A&H, same protocol as MixPad |
| **Show File Parsing** | Avoid | Undocumented TAR.GZ format, fragile across firmware versions |
| **Show File Generation** | **Do NOT generate** — use scene recall + param writes | Fragile across firmware; scene recall is stable and documented |
| **Dante Audio Streaming** | **Out of scope** — no iOS Dante support | Requires hardware adapter (AVIO USB); not practical for mobile |
| **VSC Control** | **Passive** — detect mode, provide feedback | VSC is console-side I/O routing, cannot trigger playback remotely |
| **Mixer Connection Priority** | **Read-first** before push | Enables delta analysis without risk of changing live settings |
| **Planning Center Auth** | OAuth 2.0 with PKCE | Standard iOS flow via ASWebAuthenticationSession |
| **PCO Tier Gating** | **Free — all features available** | Open-source model, no feature gating |
| **SPL Measurement** | iPhone mic with calibration | Practical for volunteers; Apple Watch as future secondary point |
| **SPL Target** | User-configurable (default 90 dB) | Preference, not hard limit |
| **SPL Flagging** | Strict / Balanced / Variable modes | User selects sensitivity |
| **Measurement Point (MVP)** | Mix position only | Simplifies calibration; multi-point is v2+ |
| **Vocalist Profiles** | Saved and reusable across services | Core workflow: define once, assign per service |
| **Donation Platform** | Church Center (Planning Center) via Victory Church AL 501(c)(3) | Tax-deductible for donors, built for churches, URL: `victorychurchal.churchcenter.com` |
| **Analysis Mode** | Both pre-service (snapshot) and during-rehearsal (live) | Snapshot for MVP, live for Sprint 3 |

### TCP/MIDI Protocol Key Facts
- **Port:** 51325 (unsecured), 51327 (TLS)
- **Max connections:** 40 TCP (shared with MixPad, Director, OneMix)
- **Readable params:** Gain, pad, 48V, HPF, LPF, gate, PEQ (4 bands), compressor, fader, channel name/color, metering, scenes
- **Protocol spec:** Allen & Heath publishes PDF — `Avantis-MIDI-TCP-Protocol-V1.0.pdf`
- **Reference implementation:** `github.com/togrupe/dlive-midi-tools` (Python, works with Avantis)

---

## ⚠️ Known Limitations & Assumptions

1. **Gain model is approximate.** Real-world gain staging depends on mic placement distance, cable runs, pad switches, and individual mic sensitivity curves. Our model uses reference SPL values and mic-class offsets. It's a strong starting point, not a replacement for soundcheck.

2. **EQ recommendations are subtractive-first.** We bias toward cuts over boosts (audio engineering best practice). Boosts are used sparingly for presence/air and are kept under +3 dB.

3. **Compressor settings are conservative.** Ratios stay between 2:1 and 4:1. We never suggest limiting (10:1+) because volunteers can easily create pumping artifacts with aggressive compression.

4. **Key-aware EQ generates per-song suggestions.** In a 5-song setlist with 15 channels, this can produce a large number of EQ recommendations. The deduplication logic merges bands within 15% frequency proximity to keep it manageable, and we cap at the mixer's physical EQ band count.

5. **Room acoustics are estimated.** Without actual measurement, our RT60 values are rough approximations. The planned CoreAudio module will solve this, but for now, the 3×3 matrix provides useful directional guidance.

6. **No monitor/IEM mix recommendations yet.** This engine focuses on FOH (Front of House). In-ear monitor mixes are a different problem with different priorities (more vocal, less room).

---

## 🧠 Domain Glossary

| Term | Meaning |
|---|---|
| **dBFS** | Decibels relative to Full Scale. 0 dBFS = digital maximum (clip point). |
| **dBu** | Decibels relative to 0.775V. Professional line level = +4 dBu. |
| **dB SPL** | Sound Pressure Level in decibels. 94 dB SPL = standard vocal reference. |
| **Gain Staging** | Setting the preamp gain so the signal hits the target level (-18 dBFS) with adequate headroom. |
| **HPF / High-Pass Filter** | Removes frequencies below a cutoff point. Essential for eliminating rumble, handling noise, and stage bleed. |
| **RT60** | Reverberation Time — seconds for sound to decay by 60 dB. Longer = more reverberant room. |
| **Unity Gain** | Fader position where no boost or cut is applied (0 dB on digital consoles). |
| **FOH** | Front of House — the main speaker mix the congregation hears. |
| **DI / Direct Input** | A signal path that goes directly into the console without a microphone (e.g., keyboard, bass guitar, tracks). |
| **Proximity Effect** | Bass frequency buildup when a directional mic is used very close to the source. |
| **Q Factor** | Width of an EQ band. Higher Q = narrower cut/boost. Lower Q = wider. |
| **Headroom** | The dB distance between your operating level and digital clip (0 dBFS). At -18 dBFS target, headroom = 18 dB. |
| **HOW** | House of Worship — the venue/context this app serves. |

---

## 💬 Session Continuity Notes

When resuming work on this project:
1. The codebase is **~60 Swift files** across iOS app, watchOS companion, and widget targets. All compile and pass 261+ tests.
2. The **ViewModel** (`ServiceSetupViewModel`) lives in its own file at `ViewModels/ServiceSetupViewModel.swift` (extracted in Sprint B).
3. All audio math constants are defined in `AudioConstants` struct (`Models/AudioConstants.swift`) and mixer-specific values in `MixerModel` enum (`Models/MixerModel.swift`). If you need to tweak the gain model or add a new mixer, those are the two places to look.
4. The `BoothColors` struct delegates to `ThemeProvider.activeColors` (5 themes). Use `BoothColors` everywhere — never hardcode colors.
5. OSLog logging is available via `AppLogger.swift` — use `Logger.persistence`, `.network`, `.audio`, `.engine`, `.connectivity` for structured logging.
6. **Next milestone:** TestFlight provisioning and internal beta distribution.
7. **Next feature work:** Live mixer push (Phase 2+), Watch-independent SPL measurement.
