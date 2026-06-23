# Final Export QA Checklist

Run these checks before shipping the native export system.

## Scripts

```bash
bash scripts/export_production_smoke.sh
bash scripts/android_device_export_qa.sh
bash scripts/ios_device_export_qa.sh
bash scripts/export_edge_case_qa.sh
```

## Android checks

- Flutter analyzer passes.
- Android debug build passes.
- App runs on a real Android device.
- Single clip export works with original media.
- Single clip export works with proxy media.
- Multi-clip export works.
- Overlapping audio, volume, and fades are correct in the final file.
- Text and image overlays appear in the final file.
- Cancelled export removes partial output.
- Failed export removes partial output.
- Retry creates a new export job and fresh output path.
- Missing media fails during preflight.
- Missing or empty output is not marked completed.

## iOS checks

- Flutter analyzer passes.
- Pod install passes.
- Xcode simulator build passes.
- App runs on a real iPhone.
- Single clip export works with original media.
- Single clip export works with proxy media.
- Multi-clip export works.
- AVAudioMix volume and fades are correct in the final file.
- Text and image overlays appear in the final file.
- Cancelled export removes partial output.
- Failed export removes partial output.
- Retry creates a new export job and fresh output path.
- Missing media fails during preflight.
- Missing or empty output is not marked completed.

## Edge-case checks

- Missing original and missing proxy fails before native export starts.
- Missing proxy with original available follows original fallback policy.
- Missing original with proxy available works in proxy-preferred mode.
- Empty native output becomes failed.
- Partial output is removed after failed or cancelled export.
- Stale active jobs can be recovered into a terminal failed state.
- Completed exports are not deleted by cache cleanup.

## Current known limitations

- Android true PCM mixdown is active on the composited export path. A simple one-clip pass-through export can still use direct muxing unless routed through the compositor.
- iOS uses AVFoundation composition and AVAudioMix for overlap, volume, and fades, not a custom PCM mixer.
- Real device testing is still required for codec behavior, content URI access, large files, and long exports.
