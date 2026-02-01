#!/bin/bash

# Check for API Keys
if [ -z "$GEMINI_KEY" ] || [ -z "$STABILITY_KEY" ]; then
  echo "⚠️  WARNING: GEMINI_KEY or STABILITY_KEY not found in environment."
  echo "   Use: GEMINI_KEY=... STABILITY_KEY=... ./deploy_web.sh"
  # Optional: Ask user to continue or exit? For now, we warn but allow build (features will be disabled).
  read -p "Do you want to continue with missing keys? (y/N) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

# Build the Flutter web app (release mode) with keys
echo "🚧 Building Flutter web app..."
flutter build web --release \
  --dart-define=GEMINI_KEY="$GEMINI_KEY" \
  --dart-define=STABILITY_KEY="$STABILITY_KEY" \
  --no-wasm-dry-run


# Check if build was successful
if [ $? -ne 0 ]; then
  echo "❌ Build failed! Aborting deployment."
  exit 1
fi

# Deploy to Firebase Hosting
echo "🚀 Deploying to Firebase Hosting..."
firebase deploy --only hosting

# Check if deployment was successful
if [ $? -ne 0 ]; then
  echo "❌ Deployment failed!"
  exit 1
fi

echo "✅ Deployment complete! Visit https://tellulu.web.app"
