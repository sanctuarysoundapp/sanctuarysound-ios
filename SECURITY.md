# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| 0.2.x   | Current   |
| < 0.2   | No        |

SanctuarySound is currently in closed beta. Security patches will be applied to the latest release only.

## Reporting a Vulnerability

If you discover a security vulnerability in SanctuarySound, please report it responsibly.

**How to report:**

1. **Do not** open a public GitHub issue for security vulnerabilities
2. Email **security@sanctuarysound.app** with a description of the vulnerability
3. If email is not available, open a GitHub issue with the `security` label and keep details minimal — request a private channel for full disclosure

**What to include:**
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

**What to expect:**
- Acknowledgment within 48 hours
- Status update within 7 days
- Fix timeline communicated once assessed

## Scope

The following are in scope for security reports:

- **OAuth token handling** — Storage, transmission, and lifecycle of Planning Center OAuth tokens
- **Keychain usage** — Secure storage implementation for sensitive credentials
- **Network communication** — TCP connections to mixers, HTTPS to Planning Center API
- **Local data storage** — JSON persistence of service data and user preferences
- **Privacy** — Any data collection or transmission not disclosed in PRIVACY.md

The following are **out of scope:**

- Audio calculation accuracy (not a security concern)
- UI/UX issues (use regular GitHub issues)
- Third-party service vulnerabilities (report to the respective vendor)
- Social engineering attacks

## Security Design Principles

SanctuarySound follows these security principles:

1. **No backend** — All data stays on-device. No server to compromise.
2. **Keychain for secrets** — OAuth tokens stored via iOS Keychain, never in plaintext JSON.
3. **PKCE for OAuth** — Public client flow with Proof Key for Code Exchange. No client secret.
4. **Minimal permissions** — Only requests microphone (SPL) and local network (mixer) access.
5. **No analytics** — Zero tracking, zero telemetry, zero user data collection.
