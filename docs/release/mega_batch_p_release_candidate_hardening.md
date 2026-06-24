# Mega Batch P — Real CI / Device Failure Fixes / Release Candidate Hardening

## Goal

Mega Batch P adds the first release-candidate safety layer around the editor. The goal is not to claim the app is store-ready automatically, but to make every release candidate pass repeatable checks before manual device testing.

## CI workflow

```text
.github/workflows/ci.yml
```

Runs on `master` pushes and pull requests:

```text
flutter pub get
build_runner code generation
dart format check
flutter analyze
flutter test
Android dev debug build
Android staging debug build
APK artifact upload
```

## Manual release-candidate workflow

```text
.github/workflows/release-candidate.yml
```

Runs manually through GitHub Actions and can optionally build the production app bundle:

```text
dart run tool/release_candidate_gate.dart
flutter analyze
flutter test
flutter build appbundle --release --flavor prod -t lib/main.dart
```

The production bundle build is optional because signing/release secrets may not be available in every CI environment.

## Local release gate

```text
tool/release_candidate_gate.dart
```

Checks:

```text
CI workflow exists
pubspec/version exists
.env asset exists with public Supabase config
Android dev/staging/prod flavors exist
release minify/shrink config exists
signing fallback exists
ProGuard file exists
critical architecture files exist
release signing files are not committed
```

Run locally:

```bash
dart run tool/release_candidate_gate.dart
```

Strict mode treats warnings as failures:

```bash
dart run tool/release_candidate_gate.dart --strict
```

## Smoke test

```text
test/release_candidate_smoke_test.dart
```

Provides a stable test target so CI can run `flutter test` before the deeper device/integration test matrix is added.

## Device failure reporting

```text
.github/ISSUE_TEMPLATE/device_failure_report.yml
```

Standardizes reports for:

```text
import failures
preview failures
proxy generation failures
export failures
audio mixdown failures
storage/cache cleanup failures
startup failures
```

## In-app release checklist

The release checklist now includes:

```text
GitHub CI is green
Release candidate gate passes
Production bundle generated
Low-end device export tested
Thermal/interruption behavior tested
Storage-full failure tested
```

## Required manual device matrix before release

At minimum, test on:

```text
low-end Android phone: 720p/1080p proxy export
mid-range Android phone: 1080p composited export with audio mixdown
high-end Android phone: 4K import, proxy preview, 1080p/4K export
offline mode: import from local storage and export without network
low storage mode: failed export plus cleanup recovery
interrupted export: app background/close then recovery state
```

## Current limitation

Mega Batch P adds CI and RC gates, but it does not replace real device testing. Video export, GPU preview, and Android codec behavior still require physical device validation.
