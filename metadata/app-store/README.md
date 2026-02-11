# App Store Submission Guide

## Required GitHub Secrets

Configure these in **Settings > Secrets and variables > Actions**:

| Secret | Description |
|--------|-------------|
| `ASC_KEY_ID` | App Store Connect API Key ID (e.g., `ABC123DEF4`) |
| `ASC_KEY_ISSUER_ID` | API Key Issuer ID (UUID from App Store Connect > Users and Access > Integrations) |
| `ASC_KEY_P8` | Contents of the `.p8` private key file (paste the full file content) |

### Creating an API Key

1. Go to [App Store Connect](https://appstoreconnect.apple.com) > Users and Access > Integrations > App Store Connect API
2. Click the "+" button to generate a new key
3. Name: `SanctuarySound CI` (or similar)
4. Access: `App Manager` (minimum required for upload)
5. Download the `.p8` file (available only once)
6. Note the Key ID and Issuer ID

## Release Process

1. Ensure all changes are merged to `main`
2. Create and push a version tag:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```
3. The `release.yml` workflow will automatically:
   - Run tests
   - Bump version numbers in the project
   - Archive and export the IPA
   - Upload to TestFlight
   - Create a GitHub Release with the IPA artifact

## App Store Screenshots

### Automated Capture

```bash
./scripts/capture-screenshots.sh              # Full run (all devices + watch)
./scripts/capture-screenshots.sh --iphone-only # iPhone screenshots only
./scripts/capture-screenshots.sh --watch-only  # Watch/Widget screenshots only
./scripts/capture-screenshots.sh --device "iPhone 17 Pro Max"  # Single device
```

### iPhone Screenshots (9 per device)

| Device | Resolution | Simulator | Directory |
|--------|-----------|-----------|-----------|
| iPhone 6.9" | 1320 x 2868 | iPhone 17 Pro Max | `screenshots/6.9-inch/` |
| iPhone 6.3" | 1206 x 2622 | iPhone 17 Pro | `screenshots/6.3-inch/` |
| iPhone 6.1" | 1080 x 2340 | iPhone 16e | `screenshots/6.1-inch/` |

Screens captured:
1. Services tab (with saved services)
2. Service setup wizard (Step 1)
3. Recommendations output (gain, EQ, comp cards)
4. Input Library
5. Console profiles
6. SPL Meter (active state)
7. EQ Analyzer (31-band RTA)
8. Q&A Knowledge Base
9. Settings with theme visible

### Apple Watch Screenshots (4 per size)

| Device | Resolution | Method | Directory |
|--------|-----------|--------|-----------|
| Watch Ultra 3 | 422 x 514 | ImageRenderer | `screenshots/watch-ultra-3/` |
| Watch Series 11 | 416 x 496 | ImageRenderer | `screenshots/watch-series-11/` |

Screens captured:
1. SPL Dashboard (safe state — 85 dB, green ring)
2. SPL Dashboard (alert state — 93 dB, red ring with overshoot glow)
3. Reports list (past session reports)
4. Report detail (grade, stats)

### Widget Complications (3 types)

| Type | Directory |
|------|-----------|
| Circular gauge, Corner text, Rectangular | `screenshots/watch-complications/` |

### Total: 38 screenshots (27 iPhone + 8 Watch + 3 Widget)

## App Store Metadata

| File | Description |
|------|-------------|
| `description.txt` | Full App Store description (< 4000 chars) |
| `keywords.txt` | Search keywords (< 100 chars, comma-separated) |
| `whats-new.txt` | "What's New" text for each version |

## App Information

| Field | Value |
|-------|-------|
| Bundle ID | `com.sanctuarysound.app` |
| Team ID | `M2739G49TS` |
| Category | Music |
| Secondary Category | Utilities |
| Content Rating | 4+ |
| Price | Free |
| License | MIT |
