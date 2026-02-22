#!/bin/bash

# Kill any existing process on port 4040 to avoid conflicts
lsof -t -i :4040 | xargs kill -9 2>/dev/null

echo "🚀 Compiling Tellulu Web (Release Mode)..."
echo "⏳ This will take a minute, but it will be MUCH faster to use."

# Run in Release mode (Optimized JS, no Debug overhead)
flutter run -d chrome --release --web-port 4040
