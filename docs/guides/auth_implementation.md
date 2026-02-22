# Implementation Journey: Cross-Platform Authentication
*(Jan 2026 - Debugging Google & Apple Sign-In)*

> [!NOTE]
> This guide was extracted from the main Technical Design Document (Appendix A1) to keep the architecture doc focused. It documents the debugging journey and solutions for cross-platform authentication.

## Problem Statement
The application required robust, cross-platform authentication for Google and Apple providers across three distinct targets:
- **Web:** `tellulu.web.app` (SPA)
- **Android:** Native Emulator & Devices
- **iOS:** Native Simulator & Devices

## 1. Apple Sign-In Integration
**Challenge:** Apple Sign-In behaves differently on Web (Redirect/Popup) vs. Native (System UI).
**Solution:**
- **Web/Android:** Implemented a **Service ID** based flow.
    - Configured Apple Developer Portal with Service ID (`com.tellulu.tellulu.service`).
    - Added Redirect URI: `https://tellulu.web.app/__/auth/handler`.
    - Updated Dart code to pass `webAuthenticationOptions` (clientId + redirectUri) to the `sign_in_with_apple` package. This forces the web-based "Custom Tab" flow on Android, bypassing the need for native iOS capabilities on non-iOS devices.
- **iOS:** Used Native entitlements.
    - Added "Sign In with Apple" capability in Xcode.
    - Verified `Runner.entitlements` file presence.

## 2. Google Sign-In Integration
**Challenge 1 (Web):** The "deprecated" Google Sign-In button was missing/broken.
**Solution:**
- Added `<meta name="google-signin-client_id">` to `index.html`.
- Implemented `renderButton` (GSI - Google Identity Services) for a modern, consistent UI on the Web.

**Challenge 2 (Android):** `GoogleSignInException: No credential available`.
**Root Cause:**
1.  **Emulator State:** The emulator lacked a signed-in Google account (Play Store), meaning the on-device `CredentialManager` had no credentials to offer.
2.  **Configuration:** The OAuth 2.0 flow required the **Web Client ID** (`serverClientId`) even for native Android calls to validly exchange tokens with the backend.
**Solution:**
- **Environment:** Provisioned a new Android Emulator with **Play Store** support (Pixel 5, API 34) and signed in.
- **Code:** Updated `GoogleSignIn.initialize()` to explicitly pass the `serverClientId` (from `google-services.json` "oauth_client" type 3).
- **Security:** Verified SHA-1 fingerprint of the debug keystore matched the Firebase Android App configuration.

## 3. Infrastructure & Tooling Upgrade
To support these modern authentication flows (specifically `google_sign_in` v7.0+), the entire project toolchain was upgraded:
- **Flutter SDK:** Upgraded to **3.38.9** (Stable).
- **Dependencies:**
    - `google_sign_in`: ^7.0.0
    - `sign_in_with_apple`: ^6.0.0
- **Build System:** Cleaned and rebuilt `pubspec.lock` and Podfiles to resolve version constraints.
