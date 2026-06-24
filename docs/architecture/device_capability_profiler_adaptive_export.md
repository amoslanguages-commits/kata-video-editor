# Mega Batch N — Device Capability Profiler + Adaptive Export Settings

## Goal

Mega Batch N makes export settings device-aware. The app should not blindly offer or send expensive export profiles to native code when the device codec, GPU, memory, thermal state, or color pipeline cannot handle them safely.

## Native capability profile

The native command is:

```text
probe_device_capabilities
```

It returns a stable profile envelope:

```text
profileSchema: nle.device_capability_profile
profileVersion: 1
generatedAtMs
deviceCapability
colorCapability
adaptiveExportProfile
```

`deviceCapability` comes from the existing Android collector and includes:

```text
device tier
memory
CPU cores
codec support
EGL/GLES support
thermal status
recommendation
```

`colorCapability` comes from the color pipeline scanner and includes:

```text
GLES3 support
float/half-float render target support
wide color preview
HDR preview/export
max texture size
GPU renderer/vendor
recommended color pipeline quality
```

## Adaptive export profile

The native layer now computes:

```text
maxResolution
maxFrameRate
maxVideoBitrate
audioBitrate
preferProxyPreview
proxyPolicy
requireProxyFor4k
allow4kExport
exportBlocked
blockReason
previewQuality
preferredPreviewScale
colorPipelineQuality
supportsHdrExport
supportsWideColorPreview
notes
```

This gives Flutter one simple policy object for export UI and final export job creation.

## Flutter resolver

Flutter has:

```text
lib/domain/export/device_capability_profile.dart
```

It provides:

```text
DeviceCapabilityProfile
AdaptiveExportProfile
RequestedExportSettings
AdaptiveExportSettingsResolver
AdaptiveExportSettingsDecision
```

The resolver clamps requested export settings before sending them to native:

```text
resolution
frame rate
video bitrate
audio bitrate
proxy requirement
HDR permission
```

The final native profile can include:

```text
adaptiveExport: true
adaptiveBlocked
adaptiveReasons
deviceProfile
```

## Runtime flow

```text
App startup or export screen open
  -> probe_device_capabilities
  -> parse DeviceCapabilityProfile
  -> user selects export preset
  -> AdaptiveExportSettingsResolver clamps settings
  -> start_export_job receives adaptive native profile
```

## Safety rules

Export should be blocked if:

```text
H.264 encoder is missing
AAC encoder is missing
EGL is unavailable
thermal state blocks long export
```

4K export should be hidden or disabled unless:

```text
native profile allows 4K
codec supports 4K
thermal status is safe
```

Proxy should be forced when:

```text
device tier is low-end
profile says proxy required
4K is requested but profile requires proxy for 4K
```

## Batch status

Implemented:

```text
Native probe_device_capabilities payload
Native adaptiveExportProfile calculation
Flutter typed bridge method
Flutter adaptive export profile model
Flutter adaptive export resolver
Architecture documentation
```

Remaining integration for UI batch O:

```text
Show device tier in export panel
Disable unsupported 4K/HDR toggles
Display adaptive clamp reasons
Offer proxy recommendation before export
Persist last capability profile locally
```
