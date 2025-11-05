#!/bin/bash

# Pre-publish validation script
# Run this before creating a version tag to ensure everything is ready

set -e  # Exit on any error

echo "🚀 Running pre-publish checks for shard_i18n..."
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $1"
    else
        echo -e "${RED}✗${NC} $1"
        exit 1
    fi
}

# 1. Check formatting
echo "📝 Checking code formatting..."
dart format --output=none --set-exit-if-changed .
print_status "Code formatting"

# 2. Run static analysis
echo ""
echo "🔍 Running static analysis..."
flutter analyze
print_status "Static analysis"

# 3. Run unit tests
echo ""
echo "🧪 Running unit tests..."
flutter test
print_status "Unit tests"

# 4. Check example app dependencies
echo ""
echo "📦 Checking example app..."
cd example
flutter pub get > /dev/null 2>&1
print_status "Example dependencies"

# 5. Analyze example app
flutter analyze
print_status "Example app analysis"

# 6. Build example app
echo ""
echo "🏗️  Building example app..."
flutter build apk --debug > /dev/null 2>&1
print_status "Example app build"

cd ..

# 7. Validate pubspec.yaml
echo ""
echo "📋 Validating package metadata..."

# Check if version is in pubspec.yaml
if grep -q "^version: [0-9]\+\.[0-9]\+\.[0-9]\+" pubspec.yaml; then
    print_status "Version format"
else
    echo -e "${RED}✗${NC} Invalid version format in pubspec.yaml"
    exit 1
fi

# Check if LICENSE exists and is not TODO
if [ -f "LICENSE" ] && ! grep -q "TODO" LICENSE; then
    print_status "LICENSE file"
else
    echo -e "${RED}✗${NC} LICENSE file missing or incomplete"
    exit 1
fi

# Check if CHANGELOG.md is updated
CURRENT_VERSION=$(grep "^version:" pubspec.yaml | cut -d' ' -f2)
if grep -q "\[$CURRENT_VERSION\]" CHANGELOG.md; then
    print_status "CHANGELOG.md updated"
else
    echo -e "${YELLOW}⚠${NC} CHANGELOG.md might not be updated for version $CURRENT_VERSION"
fi

# 8. Dry-run publish
echo ""
echo "🎯 Running publish dry-run..."
dart pub publish --dry-run
print_status "Publish dry-run"

# Summary
echo ""
echo -e "${GREEN}✓✓✓ All pre-publish checks passed!${NC}"
echo ""
echo "You can now create a release tag:"
echo "  git tag -a v$CURRENT_VERSION -m \"Release version $CURRENT_VERSION\""
echo "  git push origin v$CURRENT_VERSION"
echo ""
echo "Or follow the full publishing guide in PUBLISHING.md"
