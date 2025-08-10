#!/bin/bash

# Production build script for Asoud Flutter app

echo "🚀 Building Asoud Flutter App for Production..."

# Environment variables for production
export ENVIRONMENT=prod
export BASE_URL=https://api.asoud.ir
export WS_BASE_URL=wss://api.asoud.ir/ws
export ENABLE_LOGS=false
export UIUX_PREVIEW=false
export API_TIMEOUT=15

# Clean and get dependencies
echo "📦 Getting dependencies..."
flutter clean
flutter pub get

# Generate code
echo "🔧 Generating code..."
flutter packages pub run build_runner build --delete-conflicting-outputs

# Analyze code
echo "🔍 Analyzing code..."
flutter analyze

# Run tests
echo "🧪 Running tests..."
flutter test

# Build APK for production
echo "📱 Building production APK..."
flutter build apk \
  --dart-define=ENVIRONMENT=$ENVIRONMENT \
  --dart-define=BASE_URL=$BASE_URL \
  --dart-define=WS_BASE_URL=$WS_BASE_URL \
  --dart-define=ENABLE_LOGS=$ENABLE_LOGS \
  --dart-define=UIUX_PREVIEW=$UIUX_PREVIEW \
  --dart-define=API_TIMEOUT=$API_TIMEOUT \
  --release \
  --flavor prod

echo "✅ Production build completed! APK location: build/app/outputs/flutter-apk/"
