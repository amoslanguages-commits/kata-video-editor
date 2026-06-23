# 31A-QA: Beta Device Target Matrix

This document defines the device tiers, baseline configurations, and fallback targets for the professional color engine beta phase.

## Mobile Device Tiers

| Tier | Characteristics | Color Target | Fallback Target |
| :--- | :--- | :--- | :--- |
| **High-End** | Tensor G3+, Snapdragon 8 Gen 2+, Apple A16+ | HDR PQ/HLG, Display P3, 10-bit | Rec.709 SDR (Manual Override) |
| **Mid-Range** | Mali-G715, Adreno 730, Apple A14 | Display P3 SDR, Rec.709 SDR | Rec.709 SDR |
| **Low-End** | Mali-G52, Adreno 610 (GLES 2.0 / 3.0) | Rec.709 SDR | Rec.709 SDR (8-bit Compatibility) |

## Device Capability Fallback Rules

- [ ] **SDR Safety Default**: When the hardware scanner flags HDR metadata encoder failures (e.g. `encoderSupportsTenBit == false`), the pipeline must suggest a downgrade to `displayP3Sdr` or `rec709Sdr`.
- [ ] **Compatibility Render Mode**: GLES context bounds (e.g. max texture size < 4096) trigger `compatibility` precision mode in `NleSceneLinearGpuPipelineRenderer` (8-bit fixed rendering).
- [ ] **Thermal / Memory Stress**: If memory pressure goes beyond warning limits, the preview quality falls back to `medium` or `low` to release GPU texture overhead.
