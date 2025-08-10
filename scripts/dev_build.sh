#!/bin/bash

# Development build script for Asoud Flutter app

echo "🚀 Building Asoud Flutter App for Development..."

# Environment variables for development
export ENVIRONMENT=dev
export BASE_URL=https://api.asoud.ir
export WS_BASE_URL=wss://api.asoud.ir/ws
export ENABLE_LOGS=true
export UIUX_PREVIEW=true
export API_TIMEOUT=30

# Clean and get dependencies
echo "📦 Getting dependencies..."
flutter clean
flutter pub get

# Generate code (including Retrofit and json_serializable)
echo "🔧 Generating code..."
flutter packages pub run build_runner build --delete-conflicting-outputs

# Analyze code
echo "🔍 Analyzing code..."
flutter analyze

# Run tests (including contract tests)
echo "🧪 Running tests..."
flutter test test/
flutter test test/api/

# Build and run for development
echo "📱 Running in development mode..."
flutter run \
  --dart-define=ENVIRONMENT=$ENVIRONMENT \
  --dart-define=BASE_URL=$BASE_URL \
  --dart-define=WS_BASE_URL=$WS_BASE_URL \
  --dart-define=ENABLE_LOGS=$ENABLE_LOGS \
  --dart-define=UIUX_PREVIEW=$UIUX_PREVIEW \
  --dart-define=API_TIMEOUT=$API_TIMEOUT

echo "✅ Development build completed!"
