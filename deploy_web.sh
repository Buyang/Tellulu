#!/bin/bash

# Build the Flutter web app (release mode) with keys from .env
echo "🚧 Building Flutter web app..."
# Note: --dart-define-from-file=.env handles reading the file directly.
# Ensure .env exists or this will fail.
if [ ! -f ".env" ]; then
    echo "❌ Error: .env file not found! API keys are required for build."
    exit 1
fi

flutter build web --release \
  --dart-define-from-file=.env


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
