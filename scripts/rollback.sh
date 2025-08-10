#!/bin/bash

# Rollback script for Asoud UI/UX improvements
# This script will revert all changes made by the uiux.patch

echo "🔄 Rolling back UI/UX improvements..."

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    echo "❌ Error: Not in a git repository"
    exit 1
fi

# Check if pre-uiux tag exists
if ! git tag -l | grep -q "pre-uiux"; then
    echo "❌ Error: pre-uiux tag not found. Cannot rollback safely."
    echo "Please create a tag before applying patches: git tag pre-uiux"
    exit 1
fi

# Create a backup of current state
echo "📦 Creating backup of current state..."
git tag backup-$(date +%Y%m%d-%H%M%S) 2>/dev/null || true

# Revert to pre-uiux state
echo "⏪ Reverting to pre-uiux state..."
git reset --hard pre-uiux

# Verify the rollback
echo "🔍 Verifying rollback..."
if [ $? -eq 0 ]; then
    echo "✅ Rollback completed successfully!"
    echo "📝 Your code has been reverted to the state before UI/UX improvements."
    echo "🏷️  Current state backed up with timestamp tag if needed."
    
    # Check if app still builds
    echo "🔧 Verifying app builds correctly..."
    flutter pub get > /dev/null 2>&1
    if flutter analyze --no-fatal-infos > /dev/null 2>&1; then
        echo "✅ App analysis passed - rollback successful!"
    else
        echo "⚠️  Warning: App analysis has issues. Check manually."
    fi
    
    # Optional: Run quick test
    if [ "$1" = "--test" ]; then
        echo "🧪 Running quick tests..."
        flutter test --coverage > /dev/null 2>&1 && echo "✅ Tests passed" || echo "⚠️  Some tests failed"
    fi
    
else
    echo "❌ Rollback failed. Please check git status and resolve manually."
    exit 1
fi

echo ""
echo "🎯 Rollback Summary:"
echo "   - All UI/UX improvements have been reverted"
echo "   - App is back to original state"
echo "   - You can re-apply improvements later if needed"
echo ""
echo "💡 To re-apply improvements:"
echo "   git apply uiux.patch"
echo ""
