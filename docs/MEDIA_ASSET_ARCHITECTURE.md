# Canonical Media Asset Architecture

This app uses `MediaAssets` as the production media asset model.

## Canonical table

`MediaAssets` is the authoritative table for imported media, proxy status, availability, metadata, and media lifecycle. New import, proxy, cache, render graph, and export code should read and write through `MediaAssetRepository` or a service that depends on it.

The older `Assets` table is not the production media model. Existing records can be promoted into `MediaAssets` by `MediaAssetCanonicalizationService` so project data has one canonical asset identity.

## Required path semantics

Media paths must never be overloaded.

| Field | Meaning |
| --- | --- |
| `originalPath` | Original user-selected media location. |
| `projectPath` | App-controlled project copy of original-quality media. |
| `proxyPath` | Generated lower-cost proxy media. |
| `resolvedPath` | Actual path chosen for preview/export for this render graph. |
| `selectedMediaPath` | Alias of `resolvedPath` for native readers. |
| `sourcePolicy` | `original`, `proxy`, or `automatic`. |
| `usedProxy` | Whether this render graph selected the proxy. |

`originalPath` must always mean original media. It must not be replaced with a proxy path or a policy-selected path.

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
  "resolvedPath": "/project/proxies/video_proxy.mp4",
  "selectedMediaPath": "/project/proxies/video_proxy.mp4",
  "sourcePolicy": "proxy",
  "usedProxy": true
}
```

Native Android/iOS code should prefer `resolvedPath` or `selectedMediaPath` when present, then fall back according to `sourcePolicy`.

## Production rules

- New import code must create `MediaAssets` rows.
- New proxy code must update `MediaAssets.proxyStatus`, `proxyPath`, and proxy metadata.
- New render/export code must use `MediaAssets` through the render graph.
- Cache cleanup must never delete `originalPath` or `projectPath` media unless a project delete operation explicitly owns that path.
- Missing media detection must mark `availability = missing` and preserve the last known path.
- Relinking must update `originalPath` or `projectPath` and return the asset to `available`.
