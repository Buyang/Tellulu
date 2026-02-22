#!/bin/bash
# run_web_fixed.sh

# Kills any existing flutter instances (optional, use with care)
# pkill -f flutter

echo "🚀 Launching Tellulu Web on Fixed Port 4040..."
echo "⚠️  Note: Data stored in LocalStorage/Hive is bound to the port."
echo "    Always use this script to keep your data during development."

flutter run -d chrome --web-port 4040
