#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

VERSION_LINE="$(grep -E '^version:' pubspec.yaml | awk '{print $2}')"
BUILD_NAME="${VERSION_LINE%%+*}"
BUILD_NUMBER="${VERSION_LINE##*+}"

if [[ -z "$BUILD_NAME" || -z "$BUILD_NUMBER" || "$BUILD_NAME" == "$BUILD_NUMBER" ]]; then
  echo "Could not read version from pubspec.yaml" >&2
  exit 1
fi

ARCHIVE_PATH="build/ios/archive/Runner.xcarchive"
ARCHIVE_APP="$ARCHIVE_PATH/Products/Applications/Runner.app"
EXPORT_PATH="build/ios/ipa_appstore_clean"
IPA_PATH="$EXPORT_PATH/aramabul.ipa"
FINAL_IPA="aramabul-${BUILD_NAME}-build${BUILD_NUMBER}-appstore.ipa"
CHECK_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "$CHECK_DIR"
}
trap cleanup EXIT

flutter build ipa --release --build-name="$BUILD_NAME" --build-number="$BUILD_NUMBER"

# Flutter native-assets can currently package objective_c.framework with an
# iOS Simulator LC_BUILD_VERSION. App Store validation rejects that binary.
rm -rf "$ARCHIVE_APP/Frameworks/objective_c.framework"
rm -rf "$EXPORT_PATH"

xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist ios/ExportOptions.plist

unzip -q "$IPA_PATH" -d "$CHECK_DIR"
APP_DIR="$CHECK_DIR/Payload/Runner.app"

if [[ -e "$APP_DIR/Frameworks/objective_c.framework" ]]; then
  echo "Invalid IPA: objective_c.framework is still present" >&2
  exit 1
fi

codesign --verify --deep --strict --verbose=2 "$APP_DIR"

simulator_hits=0
while IFS= read -r file_path; do
  if file "$file_path" | grep -q 'Mach-O' && xcrun vtool -show-build "$file_path" 2>/dev/null | grep -q 'IOSSIMULATOR'; then
    echo "Invalid IPA: simulator platform binary found at $file_path" >&2
    simulator_hits=$((simulator_hits + 1))
  fi
done < <(find "$APP_DIR" -type f)

if [[ "$simulator_hits" -ne 0 ]]; then
  exit 1
fi

cp "$IPA_PATH" "$FINAL_IPA"
echo "Created $ROOT_DIR/$FINAL_IPA"
