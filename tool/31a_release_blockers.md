# 31A-QA: Color Engine Release Blockers Checklist

This checklist tracks critical color-related issues that block the beta release. Any item in this list MUST be resolved before shipment.

## GPU Pipeline Safety
- [ ] **Wrong Pass Ordering**: misplacement of passes (e.g. Curves before Primary) causes visual anomalies. Flagged as `NATIVE_PASS_BAD_ORDER_$pass`.
- [ ] **Missing Display Transform**: output displays without display transforms look washed out. Flagged as `NATIVE_PASS_OUTPUT_MISSING`.
- [ ] **Renderer Failures**: any GLES compilation or program linking errors.

## Database & Backward Compatibility
- [ ] **Migration Data Loss**: version 18 migrations must not corrupt or wipe project settings or existing tracks.
- [ ] **Parse Crash**: missing JSON parameters in older projects must resolve to Rec.709 SDR instead of crashing the editor thread.

## Memory Leak Rules
- [ ] **Active GL Textures**: Active GL texture count must not exceed 128 during timeline scrubbing. Flagged as `MEMORY_LEAK_GL_TEXTURES`.
- [ ] **Framebuffer Leaks**: Framebuffer allocations must not exceed 32. Flagged as `MEMORY_LEAK_GL_FBOS`.

## HDR Fallback Safety
- [ ] **Baseline Execution**: Rec.709 SDR must render successfully on all supported platforms.
- [ ] **Incompatible Target**: trying to export HDR on a device lacking HDR HEVC capabilities must trigger fallback suggestions rather than failing silently.
