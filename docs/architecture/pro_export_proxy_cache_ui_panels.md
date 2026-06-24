# Mega Batch O — Pro Export / Proxy / Cache UI Panels

## Goal

Mega Batch O exposes the native/export architecture from Mega Batches J–N through mobile-first Flutter panels.

The panels are intentionally compact because the app is mobile-first. They are designed as reusable cards that can appear inside Settings, the export sheet, project dashboard, or editor side panels.

## Added panels

```text
lib/presentation/widgets/export/pro_export_panel.dart
lib/presentation/widgets/proxy/proxy_workflow_panel.dart
lib/presentation/widgets/cache/cache_control_panel.dart
lib/presentation/screens/pro_tools/pro_tools_screen.dart
```

## Pro Export Panel

The Pro Export panel reads:

```text
app settings
monetization entitlement
pro plan rules
device capability profile
```

It shows:

```text
current default export preset
resolution clamp
frame-rate clamp
recommended codec
watermark/pro gating state
adaptive export guidance
```

This makes export readiness visible before the user starts a long native export.

## Proxy Workflow Panel

The Proxy Workflow panel reads:

```text
proxy mode
auto proxy setting
device recommended proxy height
safe preview height
Pro entitlement for batch proxy
```

It shows the mobile editing flow:

```text
Import -> Optimize -> Edit smoothly -> Export original quality
```

It also marks whether batch proxy is available or Pro-gated.

## Cache Control Panel

The Cache Control panel reads the project storage report and exposes quick cleanup actions:

```text
clear temporary render files
clear preview thumbnails/waveforms
clear generated proxies with confirmation
```

It keeps original media safe and only clears generated project files.

## Pro Tools Screen

`ProToolsScreen` combines:

```text
DeviceCapabilityCard
ProExportPanel
ProxyWorkflowPanel
CacheControlPanel
```

This screen can be linked later from:

```text
Settings
Editor top bar
Export sheet
Project dashboard
```

## Integration status

Implemented now:

```text
Reusable Pro Export panel
Reusable Proxy Workflow panel
Reusable Cache Control panel
Pro Tools screen shell
Architecture docs
```

Next UI integration work:

```text
Add Pro Tools entry button to Settings or editor toolbar
Embed ProExportPanel in the final export bottom sheet
Connect adaptive export decision directly into NativeExportService profile generation
Add batch proxy action list in media library
Persist user dismissal of export clamp warnings
```
