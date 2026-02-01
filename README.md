# Tellulu 🐰

Tellulu is a magical storytelling application built with **Flutter** that creates personalized stories and illustrations using Generative AI.

**Version:** 1.0.1+
**Techniques:** Flutter 3.x, Riverpod (State Management), Google Gemini (Text), Stability AI (Images), Firebase Hosting (Web).

---

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK**: `3.38.9` or higher (Stable channel).
- **Dart SDK**: `3.10.0` or higher.
- **API Keys**: You need keys for [Google Gemini](https://ai.google.dev/) and [Stability AI](https://stability.ai/).
- **Firebase CLI**: Required for web deployment (`npm install -g firebase-tools`).

### 1. Installation

Clone the repository and install dependencies:

```bash
git clone https://github.com/your-username/tellulu.git
cd tellulu
flutter pub get
```

### 2. Configuration (Environment Variables)

Tellulu strictly enforces security best practices and **does not hardcode API Keys**. You must provide them via a `.env` file or compile-time variables.

**Create a `.env` file in the root directory:**

```ini
GEMINI_KEY=AIzaSy...YourKeyHere
STABILITY_KEY=sk-...YourKeyHere
```

> **Note:** The `.env` file is `.gitignore`'d. Do not commit it!

### 3. Running the App

#### 📱 Mobile (Android/iOS)

Ensure you have a connected device or emulator running.

```bash
# Debug Mode (uses .env file)
flutter run

# Release Mode (requires dart-define for keys if not using dotenv fallback)
flutter run --release
```

#### 🌐 Web (WASM)

Tellulu targets **WebAssembly (Wasm)** for high-performance rendering.

```bash
# Run locally (Classic CanvasKit)
flutter run -d chrome

# Build for Production (WASM)
flutter build web --release --wasm
```

---

## 🔑 Authentication Setup

Tellulu supports Cross-Platform Authentication (Web, Android, iOS):

- **Web:** Uses Google Identity Services (GIS).
- **Android/iOS:** Uses Native Google Sign-In and Apple Sign-In.
- **Android Specifics:** verified on emulators with Play Store (API 34+).
- **Apple Sign-In:** Uses a hybrid "Web Authentication" flow on Android/Windows to support Apple ID without needing an iOS device.

---

## 🛠️ Deployment

### Web Deployment (Firebase)

The project includes an automated deployment script `deploy_web.sh` that handles cleaning, building, and deploying to Firebase Hosting.

```bash
chmod +x deploy_web.sh
./deploy_web.sh
```

**Note:** Ensure you are logged into Firebase (`firebase login`) and have the correct project selected (`firebase use your-project-id`).

---

## 🏗️ Architecture

- **`lib/features/`**: Code is organized by feature (vertical slicing).
    - `features/create`: Character creation flows.
    - `features/stories`: Story weaving and viewing logic.
    - `features/auth`: User authentication and profiles.
- **`lib/services/`**: Abstractions for external APIs (Gemini, Stability).
- **`lib/providers/`**: Global state management using **Riverpod**.
- **`docs/`**: Detailed documentation.
    - [`technical_design.md`](docs/technical_design.md): In-depth architecture and decision logs.

---

## 🧪 Testing

We use a mix of Unit and Widget tests.

```bash
# Run all tests
flutter test
```

> **Note:** Some tests mock the HTTP client to avoid network calls during CI.

---

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
