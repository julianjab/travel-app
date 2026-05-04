#!/bin/bash
set -e

# Build iOS release archive and upload to TestFlight.
#
# Prerequisites:
#   - Xcode with a valid Apple Developer account signed in
#   - Provisioning profile for com.jabsolutions.vamos installed
#   - ExportOptions.plist present in app/ios/ (copy from ExportOptions.plist.example, fill teamID)
#
# Usage:
#   ./release_build.sh                          # uses ExportOptions.plist (default)
#   ./release_build.sh MyExportOptions.plist    # uses a custom export options file

EXPORT_OPTIONS="${1:-ExportOptions.plist}"

# Resolve repo root relative to this script's location (app/ios/).
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

echo "Building Flutter iOS release (no-codesign)..."
cd "$REPO_ROOT"
flutter build ios --release --no-codesign

echo "Archiving in Xcode..."
xcodebuild -workspace ios/Runner.xcworkspace \
           -scheme Runner \
           -configuration Release \
           -archivePath build/Runner.xcarchive \
           archive

echo "Exporting IPA..."
xcodebuild -exportArchive \
           -archivePath build/Runner.xcarchive \
           -exportPath build/ios-release \
           -exportOptionsPlist "ios/$EXPORT_OPTIONS"

echo "IPA at: build/ios-release/vamos.ipa"
echo "Upload to TestFlight via Xcode Organizer or run:"
echo "  xcrun altool --upload-app -f build/ios-release/vamos.ipa -t ios --apiKey <KEY> --apiIssuer <ISSUER>"
