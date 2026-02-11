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

Required device sizes for App Store submission:

| Device | Resolution | Simulator |
|--------|------------|-----------|
| iPhone 6.9" | 1320 x 2868 | iPhone 17 Pro Max |
| iPhone 6.3" | 1290 x 2796 | iPhone 17 Pro |

Screenshots should capture these screens:
1. Services tab (with saved services)
2. Service setup wizard (Step 1)
3. Recommendations output (gain, EQ, comp cards)
4. Input Library
5. Console profiles
6. SPL Meter (active state)
7. EQ Analyzer (31-band RTA)
8. Q&A Knowledge Base
9. Settings with theme visible

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
