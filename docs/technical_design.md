# Tellulu Technical Design & Architecture

> [!NOTE]
> This is a living document tracking the technical architecture, security model, and deployment workflows of the Tellulu application.

## 1. System Overview

Tellulu is a storytelling application built with **Flutter** that leverages Generative AI to create personalized stories and illustrations.

- **Frontend:** Flutter (Mobile + Web)
- **State Management:** Riverpod (ConsumerWidget/ProviderScope)
- **AI Services:**
    - **Google Gemini:** Story generation, character profile enhancement.
    - **Stability AI:** Image generation (SDXL) for covers and page illustrations.
- **Hosting:** Firebase Hosting (Google Cloud).

## 2. Technology Stack & Toolchain

### 2.1 Core Framework
- **Language:** Dart 3.x
- **Framework:** Flutter 3.x (Web, iOS, Android)
- **State Management:** Riverpod 3.x (Generator 4.x)
- **Web Renderer:** CanvasKit / Wasm (WebAssembly) for high-performance rendering.

### 2.2 Cloud & Hosting
- **Provider:** Google Cloud Platform (GCP)
- **Hosting:** Firebase Hosting (Static asset serving)
- **CLI:** `firebase-tools` for deployment management.

### 2.3 AI Services
- **Text Generation:** Google Gemini API (`generativelanguage.googleapis.com`)
- **Image Generation:** Stability AI API (`api.stability.ai`)
    - Models: SDXL v1.0 / Core.

### 2.4 Development Toolchain
- **IDE:** VS Code / Android Studio
- **Version Control:** Git
- **Linting:** `flutter_lints` / `analysis_options.yaml`
- **Automation:**
    - `deploy_web.sh`: Bash script for automated cleaning, building, and deploying.

## 3. Functional Requirements

### 3.1 Character Management ("Cast")
- Users can create and manage specific characters (the "Cast").
- **Profile Enhancement:** The app uses LLMs to "enhance" raw character descriptions into rich visual prompts, stored in the "Story Bible" for consistency.

### 3.2 Story Weaving (Generation)
- **Inputs:** Users select Cast members, a "Vibe" (Theme), Reading Level, and optional "Special Touches".
- **Generation:**
    - Uses **Google Gemini** to generate title, plot, and page content.
    - Uses **Stability AI (SDXL)** to generate a Book Cover and Page Illustrations.
- **Consistency:** Uses a **Global Seed** and enhanced character prompts to ensure characters look similar across all pages of a story.

### 3.3 Library & Persistence
- Stories are saved locally to the device (using `SharedPreferences` for now).
- Users can **Read**, **Rename**, and **Delete** stories.
- **Offline Access:** Saved stories (text + base64 images) are available offline after generation.

### 3.4 Settings & Configuration
- Users can configure API Model selection (e.g., swapping Gemini versions).
- "Creativity" sliders to adjust the temperature/strength of generation.

## 4. Non-Functional Requirements (Quality Attributes)

### 4.1 Performance
- **Web Assembly (Wasm):** The web build targets Wasm (`flutter build web --wasm`) for near-native performance and smooth 60fps animations.
- **CDN Delivery:** Firebase Hosting ensures fast global asset delivery via Google's edge caching network.

### 4.2 Security & Privacy
- **Local-First Data:** User stories and character data are stored locally on the device. No user content is sent to a backend database, minimizing data privacy risks.
- **API Security:** 
    - API Keys are not hardcoded.
    - Strict **Content Security Policy (CSP)** blocks unauthorized scripts.
    - API Keys are restricted by referer (`https://tellulu.web.app`) in the Cloud Console.

### 4.3 Reliability
- **Offline Capability:** Once downloaded/generated, stories are available without an internet connection.
- **Graceful Error Handling:** The UI provides feedback (Snackbars) for API failures (e.g., rate limits, connectivity) without crashing the app.

### 4.4 Usability
- **Responsive Design:** The layout adapts to different screen sizes (Mobile vs. Desktop/Web) using `LayoutBuilder` and flexible widgets.
- **Visual Feedback:** Loading states and animations indicate AI generation progress ("Weaving story...").

## 5. Architecture

### 5.1 Architectural Principles

The Tellulu architecture is guided by the following core principles:

1.  **Modular:** The codebase is organized by **Feature** (e.g., `features/stories`, `features/create`), encapsulating all related UI, logic, and state. This separation of concerns simplifies maintenance and allows disjoint teams to work on different parts of the app without collision.
2.  **Service Orientation:** External capabilities (AI Providers, Data Persistence) are abstracted into dedicated **Service Classes** (e.g., `GeminiService`, `StabilityService`). The UI interacts with these services via clean interfaces, decoupling the presentation layer from the underlying implementation or provider.
3.  **AI First:** The system is designed around Generative AI as a primary capability, not an afterthought. Data models (`Story`, `Cast`) are specifically structured to hold prompts, seeds, and enhanced descriptions ("Story Bible") to maximize the quality and consistency of AI outputs.
4.  **Zero Trust:** We assume the client environment is untrusted. Security is enforced through strict **Content Security Policies (CSP)**, environment-variable injection for secrets, and reliance on provider-side controls (API Key restrictions) rather than obscuring secrets in client code.
5.  **User Centric:** The architecture prioritizes user ownership and experience. Data is stored **Local-First** (`SharedPreferences`) to respect privacy. The app is built to be **Offline-Capable** and **Responsive** across devices, ensuring a seamless experience regardless of context.
6.  **Minimal Technical Debt:** We maintain a high standard of code hygiene through strict linting, automated build scripts (`deploy_web.sh`), and evergreen documentation (`TECHNICAL_DESIGN.md`). We prioritize refactoring complex logic (like Story Weaving) into manageable units to prevent "spaghetti code."

### 5.2 Core Components

- **`GeminiService`**: Handles text generation APIs.
- **`StabilityService`**: Handles image generation APIs.
- **`StoriesPage`**: Main UI for viewing and weaving stories.
    - Implements "Story Bible" logic: Character descriptions are enhanced by Gemini once and stored to ensure consistent character traits across illustrations.
    - Uses a "Global Seed" per story to maintain visual style consistency across pages.

### 5.3 Web Deployment

The web version is a Single Page Application (SPA) deployed to Firebase Hosting.

- **Build:** `flutter build web --release --wasm` (WASM supported)
- **Routing:** Handled by `firebase.json` rewrites.
- **URL:** `https://tellulu.web.app`

### 5.4 Web Deployment Strategy & Caching

#### Issue: The "Zombie" Service Worker
Flutter Web's default PWA setup includes a Service Worker that caches `index.html`. While this enables offline support, it can cause severe "Zombie Cache" issues where deployed hotfixes (e.g., CSP headers, renderer fixes) are ignored by the browser because it serves the stale, broken file from cache.

#### Decision: Prioritize Stability over Offline Mode
For the **V1 Launch**, we have explicitly **disabled and unregistered** the Service Worker.

**Implementation**:
- In `index.html`, `serviceWorker` is set to `null` in the Flutter configuration.
- A script runs on boot to forcibly unregister any existing Service Workers.
- `firebase.json` sets `Cache-Control: no-cache` for `index.html`.

**Trade-off**:
- **Pro**: Guaranteed invalidation. Users always receive the latest deployment. Eliminates "Blank Page" loops caused by cached config errors.
- **Con**: The app cannot be loaded offline.
- **Future**: We can re-enable configured caching in V2 once the deployment pipeline and CSP are fully stabilized.

### 5.5 Authentication Architecture (v2.0)
> [!NOTE]
> Major update in v1.0.1+ (Jan 2026) to align with Google Sign-In v7.0.

- **Provider:** Google Sign-In (v7.0+)
- **Pattern:** Singleton Access via `GoogleSignIn.instance`.
- **Flow:**
    1.  **Initialization:** Asynchronous `initialize()` call on app start or page load.
    2.  **Authentication:** Explicit `authenticate()` call to verify identity.
    3.  **Authorization:** Separate step (if needed) to request data scopes (though basic profile is included in Auth).
- **Separation of Concerns:** Rigidly separates "Who you are" (AuthN) from "What you can do" (AuthZ), improving security posture.

## 6. Security Model

### API Key Management
> [!IMPORTANT]
> **NEVER hardcode API keys in source code.**

- **Development:** Keys are loaded from a `.env` file (git-ignored) via `flutter_dotenv`.
- **Production:** Keys are configured in the cloud environment or CI/CD pipeline and injected into the build/runtime.
- **Client-Side Protection:**
    - API Keys **MUST** be restricted in the Google Cloud/Provider console to `https://tellulu.web.app`.
    - **Content Security Policy (CSP):** Enforced via `firebase.json` headers to restrict script execution and API connections to trusted domains (`*.googleapis.com`, `api.stability.ai`).

## 7. Workflows

### Deployment
> [!TIP]
> Use the helper script for consistent deployments.

Run the following command to build and deploy:
```bash
./deploy_web.sh
```

**Script Actions:**
1.  Loads environment variables from `.env` or system environment.
2.  Runs `flutter build web --release`.
3.  Runs `firebase deploy --only hosting`.

### Release Management
- **Versioning Strategy:** Semantic Versioning (Major.Minor.Patch)
    - **Current Version:** `1.0.0`
    - **Patch (`+1`):** Incremented for bug fixes and minor internal changes.
    - **Minor (`+0.1`):** Incremented for new features (e.g., new Character options, new Story vibes).
    - **Major (`+1.0`):** Incremented for breaking architectural changes or major re-designs.
- **Release NFRs:**
    - Version number must be visible in the **Settings** page.
    - Build verification required for Web, Android, iOS, and macOS before release.

## 8. Directory Structure

- `lib/`: Main application code.
- `web/`: Web-specific assets (icons, `manifest.json`).
- `firebase.json`: Hosting configuration and security headers.
- `deploy_web.sh`: Automated deployment script.

## 9. Test Strategy (Road to Production)

To ensure high quality in a creative, AI-driven application, we employ a layered testing strategy.

### 9.1 Unit Testing
- **Target:** Core Business Logic (e.g.,  prompt construction, JSON parsing).
- **Goal:** Verify that inputs produce expected text/command outputs.
- **Coverage:** High (100% of Service methods).

### 9.2 Widget Testing
- **Target:** Critical User Flows (e.g., Character Creation, Sign Up).
- **Goal:** Verify UI elements exist, interactions (taps, text entry) trigger expected state changes, and Mock Services receive correct calls.
- **Note:** Real API calls are MOCKED in these tests to ensure determinism and speed.

### 9.3 Creative Assurance (Manual)
- **Target:** Production AI Output Quality.
- **Goal:** Verify that the "Vibes" and "Styles" actually look good.
- **Method:** "Dogfooding." The team creates 1 full story per release candidate to verify:
    1.  Character Consistency (Does "Pip" look like "Pip" in panel 4?).
    2.  Text/Image alignment (Do the words match the picture?).

### 9.4 Release Gates
1.  **Build Verification:** `flutter build web --release` must pass.
2.  **Lint Check:** `flutter analyze` must be clean.
3.  **Green Tests:** All unit/widget tests must pass.
4.  **Smoke Test:** Manual verify of "Create Character -> Weave Story" flow on Staging.

## 10. Implementation Journey: Cross-Platform Authentication
*(Detailed breakdown of the debugging and integration process for Google & Apple Sign-In)*

### 10.1 Problem Statement
The application required robust, cross-platform authentication for Google and Apple providers across three distinct targets:
- **Web:** `tellulu.web.app` (SPA)
- **Android:** Native Emulator & Devices
- **iOS:** Native Simulator & Devices

### 10.2 Apple Sign-In Integration
**Challenge:** Apple Sign-In behaves differently on Web (Redirect/Popup) vs. Native (System UI).
**Solution:**
- **Web/Android:** Implemented a **Service ID** based flow.
    - Configured Apple Developer Portal with Service ID (`com.tellulu.tellulu.service`).
    - Added Redirect URI: `https://tellulu.web.app/__/auth/handler`.
    - Updated Dart code to pass `webAuthenticationOptions` (clientId + redirectUri) to the `sign_in_with_apple` package. This forces the web-based "Custom Tab" flow on Android, bypassing the need for native iOS capabilities on non-iOS devices.
- **iOS:** Used Native entitlements.
    - Added "Sign In with Apple" capability in Xcode.
    - Verified `Runner.entitlements` file presence.

### 10.3 Google Sign-In Integration
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

### 10.4 Infrastructure & Tooling Upgrade
To support these modern authentication flows (specifically `google_sign_in` v7.0+), the entire project toolchain was upgraded:
- **Flutter SDK:** Upgraded to **3.38.9** (Stable).
- **Dependencies:**
    - `google_sign_in`: ^7.0.0
    - `sign_in_with_apple`: ^6.0.0
- **Build System:** Cleaned and rebuilt `pubspec.lock` and Podfiles to resolve version constraints.
