# Mega Batch K — Typed Native Bridge + Versioned Render Graph

## Goal

Mega Batch K makes the Flutter ↔ native Android boundary explicit, typed, and version-aware.

Before this batch, native commands could be called with raw maps and render graph JSON could cross the bridge without a clear protocol header. After this batch, Dart has a typed bridge wrapper and both Dart/native code share stable protocol fields.

## Canonical bridge channel

The typed bridge uses the existing production channel:

```text
nle_editor/native_methods
```

The channel name is stored in `RenderGraphContract.nativeBridgeName` on Dart and mirrors `NleChannels.METHOD_CHANNEL` on Android.

## Bridge protocol fields

Every typed command should include:

| Field | Meaning |
| --- | --- |
| `protocolVersion` | Native bridge protocol version. Current value: `1`. |
| `commandId` | Per-call ID for correlation with native events/errors. |
| `projectId` | Project identity when the command is project-scoped. |
| `renderGraphJson` | Full render graph JSON when a graph is needed. |
| `renderGraphSchema` | Expected graph schema. Current value: `nle.render_graph`. |
| `renderGraphVersion` | Expected graph version. Current value: `2`. |

## Dart-side contract

Dart now provides:

- `RenderGraphContract`
- `RenderGraphNativeMethods`
- `RenderGraphVersionValidator`
- `VersionedRenderGraphPayload`
- `NleTypedNativeBridge`
- `NleNativeBridgeCommand`
- `NleNativeBridgeResponse`
- `NleNativeBridgeException`

Dart validates the render graph before sending it to native code. If the graph schema/version is unsupported, it fails before crossing the platform channel.

## Native-side contract

Android now provides:

- `NleNativeBridgeContract`
- `NleTrueExportGraphContract`

The plugin calls `NleNativeBridgeContract.requireCompatibleArgs()` before routing each method call. If a command includes protocol/render-graph fields, native code validates them before work starts.

## Render graph versioning

Current render graph:

```text
schema: nle.render_graph
version: 2
minSupportedVersion: 2
maxSupportedVersion: 2
```

A future render graph change must bump `RenderGraphContract.version`, then update the Dart validator and Android `NleNativeBridgeContract` supported range.

## Compatibility rule

Mega Batch K is backward-compatible with older direct MethodChannel callers:

- Commands without typed protocol fields still route through the existing native command router.
- Commands with typed protocol fields are validated strictly.
- New app code should use `NleTypedNativeBridge` instead of direct raw MethodChannel calls.

## Failure behavior

If native rejects a command before routing, the plugin returns a structured response:

```json
{
  "success": false,
  "method": "start_export_job",
  "error": {
    "code": "invalid_arguments",
    "message": "The native bridge rejected this command.",
    "technicalMessage": "..."
  }
}
```

This keeps failures synchronous and parseable on Dart.
