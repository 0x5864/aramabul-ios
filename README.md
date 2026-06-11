# AramaBul iOS

AramaBul is an Istanbul-first venue discovery app.

## Architecture

The app uses the deployed web product at `https://aramabul.com` as its only
interface source. Flutter provides the native iOS shell:

- Google sign-in bridge
- native sharing
- external map handling
- connectivity monitoring
- a native offline state

The repository does not keep a copied web snapshot. Web design and venue
behavior must be changed in the main AramaBul web repository and deployed
before they appear in the app.

## Run

"""
flutter pub get
flutter run
"""

## Verify

"""
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build ios --simulator --debug
"""

## Release

Update the version in `pubspec.yaml`, verify the deployed website, then build
the iOS archive. The `kAppVersion` value in `lib/main.dart` must match the
pubspec version name.
