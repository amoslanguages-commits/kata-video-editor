# Mega Batch L — Strict Export State Machine + Error System

## Goal

Mega Batch L turns export from loose string statuses into a strict lifecycle with typed errors.

## Canonical export states

```text
created
accepted
preflighting
queued
preparing
rendering
muxing
finalizing
completed
cancel_requested
cancelled
failed
```

## Valid transition graph

```text
created -> accepted | preflighting | queued | failed
accepted -> preflighting | queued | preparing | cancel_requested | failed
preflighting -> queued | preparing | cancel_requested | failed
queued -> preparing | cancel_requested | failed
preparing -> rendering | muxing | finalizing | cancel_requested | failed
rendering -> muxing | finalizing | cancel_requested | failed
muxing -> finalizing | cancel_requested | failed
finalizing -> completed | cancel_requested | failed
cancel_requested -> cancelled | failed
completed -> terminal
cancelled -> terminal
failed -> terminal
```

## Error contract

Every export error should carry:

| Field | Meaning |
| --- | --- |
| `code` | Stable machine-readable error code. |
| `severity` | `info`, `warning`, `recoverable`, or `fatal`. |
| `userMessage` | Short message safe to show in UI. |
| `technicalMessage` | Native/debug detail for logs. |
| `recoverySuggestion` | Next action the user can try. |
| `retryable` | Whether retry can make sense. |
| `context` | Extra structured metadata. |

## Core export error codes

```text
export_invalid_transition
export_preflight_failed
export_missing_asset
export_output_not_writable
export_encoder_failed
export_decoder_failed
export_muxer_failed
export_cancelled
export_native_failed
export_unknown_error
```

## UI rule

The export UI should never infer progress from raw event names alone. It should read:

```text
exportState
previousState
stage
progress
terminal
error
```

Legacy native event names like `export_progress`, `export_failed`, and `export_completed` can remain for compatibility, but payload state is the source of truth.

## Persistence rule

The local export job row should store:

```text
status/exportState
progress
stage
errorCode
errorJson
startedAt
completedAt/finishedAt
updatedAt
```

The current schema still has loose `status`, `progress`, `stage`, and `errorMessage`; new repository code should map the strict state machine into those existing fields until a generated Drift migration is added.

## Recovery rule

On app restart:

- `completed`, `cancelled`, and `failed` are terminal and should not auto-resume.
- `created`, `accepted`, `preflighting`, `queued`, `preparing`, `rendering`, `muxing`, `finalizing`, and `cancel_requested` are non-terminal.
- Non-terminal jobs from a previous app session should become `failed` with code `export_native_failed` and a recovery suggestion to retry export.
