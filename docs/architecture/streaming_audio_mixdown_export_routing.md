# Mega Batch M — Streaming Audio Mixdown + Export Routing Fix

## Goal

Mega Batch M makes export routing audio-aware and prepares audio mixdown for large timelines.

## Problem before M

The native composited exporter already plans audio-only tracks and mixes them into AAC, but the implementation is still memory-heavy:

- It allocates one full-timeline PCM `FloatArray`.
- It stores encoded AAC samples in memory before muxing.
- Native pass-through routing can choose the muxer path when the visual clip is simple, even if separate timeline audio tracks require mixdown.

## Routing rule

Pass-through export is only valid when all conditions are true:

```text
one clean video clip
no overlays
no text
no transform/color work
no separate timeline audio mixdown
```

If `requiresAudioMixdown` is true, export must use the composited route even when the video side looks pass-through-safe.

## Path rule

Audio mixdown should use the same media routing decision as video export:

```text
prefer proxy -> proxyPath first, then project/original/resolved fallback
prefer original -> resolved/project/original first, proxy last
```

This prevents audio from accidentally decoding the wrong source while video export uses proxy or selected media.

## Streaming rule

The long-term native implementation should avoid storing encoded AAC bytes in RAM. The preferred model is:

```text
PCM decode/mix window -> AAC encoder -> temp AAC sample file -> muxer reads samples by offset
```

This means the app can keep only sample metadata in memory:

```text
fileOffset
size
presentationTimeUs
flags
```

The muxer then reads encoded bytes from the temp file in order and deletes the temp file after success, cancellation, or failure.

## Current M commits

This batch adds:

- Dart `ExportRoutingPolicy` for shared routing decisions.
- Native audio planner path fix so proxy-routed export uses proxy paths first.
- This architecture contract for the remaining native streaming upgrade.

## Remaining native work

The full native streaming rewrite should update:

```text
android/app/src/main/kotlin/com/kata/videoeditor/nle/export/NlePcmAudioMixdownRenderer.kt
android/app/src/main/kotlin/com/kata/videoeditor/nle/export/NleCompositedExportRenderer.kt
android/app/src/main/kotlin/com/kata/videoeditor/nle/export/NleNativeExportRenderer.kt
```

Required native changes:

1. `NleEncodedAacSample` should store temp-file offsets and sizes instead of `ByteArray` data.
2. `NleEncodedAacMixdown` should own a temp AAC file path and delete it after muxing.
3. `writeEncodedAudioMixdown(...)` should stream chunks from the temp file into `MediaMuxer`.
4. `NleNativeExportRenderer` should force composited routing when render graph export hints say audio mixdown is required.
