# Mega Batch O — Pro Export / Proxy / Cache UI Panels

## Goal

Mega Batch O gives the mobile editor a premium control surface for export, proxy workflow, and generated-file cleanup.

## New screen

```text
lib/presentation/screens/pro/pro_control_center_screen.dart
```

The screen uses three mobile-first tabs:

```text
Export
Proxy
Cache
```

It is reachable from project cards on the dashboard through the pro/sparkle shortcut.

## Export panel

The export panel shows:

```text
device capability card
adaptive export guardrails
smart export preset list
active export progress and cancel action
```

Preset actions apply the device profile before starting export:

```text
resolution clamp
frame-rate clamp
4K proxy recommendation
adaptive metadata in export settings
```

## Proxy panel

The proxy panel shows:

```text
video asset count
ready proxy count
queued jobs
running state
proxy preview toggle
auto-generate toggle
pause-during-playback toggle
proxy resolution selector
queue start/stop controls
manual proxy generation per asset
unused/all proxy cleanup
```

It reuses the existing project proxy controller and queue runner.

## Cache panel

The cache panel reuses the existing project storage panel:

```text
thumbnails
timeline thumbnails
waveforms
proxies
exports
temporary render files
autosaves
other generated files
```

Cleanup actions call the existing cache storage service and refresh project storage reports.

## Integration

Dashboard project cards now include a pro shortcut that opens:

```text
ProControlCenterScreen(projectId: project.id)
```

This avoids risky changes to the large editor layout while still giving every project direct access to the new professional management panels.

## Remaining UI work for future polish

```text
Replace the old modal export dialog with the new export panel.
Add adaptive warnings directly beside the editor export button.
Persist the last selected export preset per project.
Add batch proxy selection filters.
Show cache cleanup history.
```
