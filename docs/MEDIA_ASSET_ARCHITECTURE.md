# Canonical Media Asset Architecture

This app uses `MediaAssets` as the production media asset model.

## Canonical table

`MediaAssets` is the authoritative table for imported media, proxy status, availability, metadata, and media lifecycle. New import, proxy, cache, render graph, and export code should read and write through `MediaAssetRepository` or a service that depends on it.

The older `Assets` table is not the production media model. Existing records can be promoted into `MediaAssets` by `MediaAssetCanonicalizationService` or `MediaAssetRepository.migrateLegacyAssetsForProject()` so project data has one canonical asset identity.

## Required path semantics

Media paths must never be overloaded.

| Field | Meaning |
| --- | --- |
| `originalPath` | Original user-selected media location captured at import. |
| `projectPath` | App-controlled project copy or relinked full-resolution media location. |
| `proxyPath` | Generated lower-cost proxy media. |
| `resolvedPath` | Full-resolution current source path after availability/relink checks. |
| `selectedMediaPath` | Concrete media path selected for this preview/render/export pass. |
| `sourcePolicy` | `full_resolution`, `proxy_ready`, or another explicit policy label. |
| `usedProxy` | Whether this render graph selected the proxy. |

`originalPath` always means original import source. It is not replaced by proxy selection, render graph resolution, export policy, cache movement, or relink.

## Lifecycle

The app-level lifecycle is:

```text
imported -> analyzed -> proxyNeeded -> proxyQueued -> proxyGenerating -> proxyReady
imported -> analyzed -> missing -> relinked -> analyzed
imported -> analyzed -> offline
imported -> analyzed -> corrupted
```

Lifecycle state is computed from canonical fields:

- `availability`
- `proxyStatus`
- media metadata JSON
- original/project/proxy paths

## Render graph contract

Render graph assets must include:

```json
{
  "id": "asset-id",
  "originalPath": "/original/location/video.mp4",
  "projectPath": "/project/media/video.mp4",
  "proxyPath": "/project/proxies/video_proxy.mp4",
  "resolvedPath": "/project/media/video.mp4",
  "selectedMediaPath": "/project/proxies/video_proxy.mp4",
  "sourcePolicy": "proxy_ready",
  "usedProxy": true
}
```

Native Android/iOS code should prefer `selectedMediaPath` when present, then `resolvedPath`, then fall back according to `sourcePolicy`.

## Production rules

- New import code must create `MediaAssets` rows.
- New proxy code must update `MediaAssets.proxyStatus`, `proxyPath`, and proxy metadata.
- New render/export code must use `MediaAssets` through the render graph.
- Cache cleanup must never delete `originalPath` or `projectPath` media unless a project delete operation explicitly owns that path.
- Missing media detection must mark `availability = missing` and preserve the last known path.
- Relinking must write the new usable full-resolution path to `projectPath`/resolved path selection and return the asset to `available`; it must preserve `originalPath` as import history.
