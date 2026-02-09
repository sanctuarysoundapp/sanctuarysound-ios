# Privacy Policy — SanctuarySound

**Last Updated:** February 9, 2026

SanctuarySound ("the App") is committed to protecting your privacy. This policy explains what data the App collects, how it is used, and your rights.

## Data Collection

**SanctuarySound collects no personal data.** The App does not transmit any information to external servers, third-party services, or analytics platforms.

## Microphone Access

The App requests microphone access solely for **real-time Sound Pressure Level (SPL) measurement**. Audio data from the microphone is:

- Processed locally on your device in real time
- Used only to calculate decibel levels for the SPL monitoring feature
- **Never recorded, stored, or transmitted** to any server or third party
- Discarded immediately after the SPL reading is computed

You may deny microphone access at any time via iOS Settings. The App will continue to function for all features except SPL monitoring.

## Local Data Storage

All user data (services, vocalist profiles, input presets, mixer snapshots, SPL preferences, and session reports) is stored **locally on your device** in the app's Documents directory as JSON files. This data:

- Never leaves your device
- Is not synced to any cloud service
- Is not accessible to other apps
- Is deleted when you uninstall the App

## Donations

SanctuarySound is free and open-source. Voluntary donations are processed through external platforms (church ministry website and GitHub Sponsors). The App does not collect, process, or have access to any payment or donor information. Donation links in the app open your web browser — no payment data passes through the app.

## Planning Center Online Integration

SanctuarySound optionally connects to **Planning Center Online** (PCO) to import service plans, setlists, and team rosters. When you use this feature:

- **OAuth 2.0 authentication** is used — the App never sees or stores your Planning Center password
- **OAuth tokens** are stored securely in the iOS Keychain on your device
- The App only requests **read access** to your service plans, songs, and team members
- **No data is sent** from the App to Planning Center — communication is one-way (import only)
- You can disconnect at any time via the Settings tab, which removes stored tokens

## Apple Watch Companion

If you use the watchOS companion app:

- SPL readings are relayed from iPhone to Apple Watch via **WatchConnectivity** (a private Apple framework)
- Data travels directly between your paired devices over Bluetooth/Wi-Fi — it does not pass through any external server
- Session reports are transferred to the Watch for local viewing

## Third-Party Services

SanctuarySound does **not** integrate with any third-party analytics, advertising, crash reporting, or tracking services. The only external service is Planning Center Online, which is optional and user-initiated.

## Children's Privacy

The App does not knowingly collect information from children under the age of 13. The App contains no advertising, social features, or data collection mechanisms.

## Changes to This Policy

If this policy is updated, the changes will be posted here with an updated "Last Updated" date. Continued use of the App after changes constitutes acceptance of the revised policy.

## Contact

For privacy questions or concerns, please open an issue on our GitHub repository:
https://github.com/sanctuarysoundapp/sanctuarysound-ios/issues
