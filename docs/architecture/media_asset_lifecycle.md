# Mega Batch J — Canonical Media Asset Lifecycle

## Canonical model decision

`MediaAssets` is the canonical asset model for all new media pipeline work.

The older `Assets` table is now treated as a legacy compatibility source only. New import, analysis, proxy, cache, render, and export code must read/write through `MediaAssetRepository`, which adapts legacy rows into `NleMediaAsset` records when needed.

## Path contract

A media asset may have several paths, but each path has a different job.

| Field | Purpose | Mutation rule |
| --- | --- | --- |
| `originalPath` | Import-time source path or URI. | Preserve forever. Never overwrite during proxy, cache, render, export, missing detection, or relink. |
| `projectPath` | Durable full-resolution project-owned path, or relinked full-resolution path until a dedicated DB column is added. | May change when copied into project storage or relinked. |
| `resolvedPath` | Canonical full-resolution path after availability and relink resolution. | Computed by `MediaAssetRepository`; do not open files by guessing this manually. |
| `proxyPath` | Optimized edit/proxy media path. | Written only by proxy generation. |
| `selectedMediaPath` | Concrete path selected for the current preview/render/export operation. | The only path render/export/decoder code should open. |

## Lifecycle

The lifecycle is deliberately simple and user-safe:

```text
imported → analyzed → proxy_needed → proxy_ready → missing → relinked
```

### imported

A row exists in `MediaAssets` with an immutable `originalPath`, basic file info, and no trusted analysis yet.

### analyzed

Metadata extraction has filled video/audio/timecode/file info. The asset is still full-resolution unless proxy generation is requested.

### proxy_needed

The asset should receive a proxy. `MediaAssetRepository.markProxyNeeded()` and `enqueueProxyJob()` move the asset into this state without changing `originalPath`.

### proxy_ready

Proxy generation succeeded. `proxyPath` is available and `selectedMediaPath` may choose the proxy for preview/render when `preferProxy` is true.

### missing

The full-resolution asset cannot be found. Availability is set to `missing`, and path selection returns null so the render graph cannot accidentally open stale paths.

### relinked

The user selected a new full-resolution location. The repository stores the new usable path separately from `originalPath`; it does not erase import history.

## Repository rules

All pipeline layers must use these repository calls instead of directly reading path fields:

- Import: `importAsset()` or `saveAsset()`
- Analysis: `markAnalyzed()`
- Proxy: `markProxyNeeded()`, `enqueueProxyJob()`, `setProxyReady()`, `setProxyFailed()`, `clearProxy()`
- Missing media: `markMissing()`
- Relink: `relinkAsset()`
- Render/export path selection: `resolveAssetForRender()` or `resolveAssetsForRender()`
- Legacy migration: `migrateLegacyAssetsForProject()`

## Render/export graph rule

Render and export payloads should include:

```json
{
  "originalPath": "import-time source, do not open by default",
  "resolvedPath": "full-resolution current source",
  "selectedMediaPath": "path decoder should open",
  "usingProxy": true
}
```

Native render/export models keep `path` only as a deprecated compatibility alias. The decoder-facing field is `selectedMediaPath` / `decoderPath`.

## Cleanup rule

Do not add temporary fallback comments such as “TODO use real repository later” around media paths. If a pipeline needs media, it should depend on `MediaAssetRepository` now. If a legacy source is unavoidable, migrate it through the adapter first.
