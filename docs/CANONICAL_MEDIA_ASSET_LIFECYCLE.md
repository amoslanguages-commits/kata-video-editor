# Canonical Media Asset Lifecycle

`MediaAssets` is the canonical media model for the editor.

The older `Assets` table is not a second production model. It exists only for project compatibility and migration. New production code should read and write through `MediaAssets` and `MediaAssetRepository`.

## Canonical asset fields

- `originalPath`: the original user media path or original external reference.
- `projectPath`: the copied project-local media path when the asset is stored inside the project.
- `proxyPath`: the generated proxy media path.
- `thumbnailPath`: the generated thumbnail path.
- `waveformCacheId`: the waveform cache reference.
- `availability`: current source availability state.
- `proxyStatus`: current proxy generation state.
- `fileInfoJson`: file identity, size, extension, and timestamps.
- `videoInfoJson`: video metadata.
- `audioInfoJson`: audio metadata.
- `timecodeInfoJson`: duration, FPS, and timecode metadata.

## Render graph path contract

Render graph assets must never overload `originalPath` with a proxy path.

The contract is:

```text
originalPath = original user media or external reference
projectPath = copied project-local media
proxyPath = generated proxy media
resolvedPath = media path selected for this preview/export operation
selectedMediaPath = alias of resolvedPath for native readers
sourcePolicy = original | proxy | automatic
usedProxy = true only when resolvedPath came from proxyPath
```

## Lifecycle

```text
imported
  ↓
analyzed
  ↓
proxy_needed / proxy_queued / proxy_generating
  ↓
proxy_ready
  ↓
used_in_timeline
  ↓
missing / relinked / archived
```

## State meanings

### imported

The asset has a database row and at least one source path.

### analyzed

The asset has populated file/video/audio/timecode metadata.

### proxy_needed

The device/profile/project settings require a proxy before smooth preview or draft export.

### proxy_queued

A proxy job exists but has not started.

### proxy_generating

A native proxy job is running.

### proxy_ready

`proxyPath` points to an existing generated proxy file and `proxyStatus == ready`.

### used_in_timeline

At least one clip references the asset id.

### missing

The original/project path is unavailable and the asset cannot be resolved for the requested media policy.

### relinked

The user or recovery system restored the asset path and availability returned to available.

## Repository rule

All new production code should use:

```text
MediaAssetRepository
```

Avoid writing directly to the old `Assets` table from new features.

## Migration rule

Existing project records can be migrated by `MediaAssetMigrationService`. This is a one-way project upgrade step. It should not become a long-term dual-write runtime.

## Export/proxy/cache rule

Export, proxy, preview, waveform, thumbnail, and cache systems should all use the same canonical asset id and should not create independent media identity systems.
