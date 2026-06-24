## Summary

Describe the change and why it is needed.

## Area touched

- [ ] Flutter UI/state
- [ ] Drift database/schema
- [ ] Timeline/editing
- [ ] Native bridge
- [ ] Android native preview/export/proxy/audio
- [ ] iOS native preview/export/proxy/audio
- [ ] Cache/proxy/recovery
- [ ] QA/CI/scripts/docs

## Required local gates

Paste results or explain why a gate is not applicable.

- [ ] `dart format --set-exit-if-changed lib test`
- [ ] `flutter analyze`
- [ ] `flutter test`
- [ ] `flutter build apk --debug`
- [ ] `bash scripts/export_production_smoke.sh`

## Native/device gates

Required for export, proxy, preview, audio, render graph, or native bridge changes.

- [ ] `bash scripts/strict_native_gate.sh`
- [ ] Android real-device export tested
- [ ] iOS real-device export tested
- [ ] Missing media preflight tested
- [ ] Proxy/original mode tested
- [ ] Cancel/retry tested

## Risk checklist

- [ ] No user original media is deleted by cache/recovery code
- [ ] Failed/cancelled export does not leave partial output behind
- [ ] Completed export has a real non-empty output file
- [ ] New native errors are mapped to clear user-facing messages or tracked as TODO
- [ ] Known limitations are documented

## Screenshots / logs

Attach logs, screenshots, or device notes here.
