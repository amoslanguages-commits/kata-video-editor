# 31A-QA: Preview vs. Export Rendering Match Checklist

This checklist verifies that the preview program monitor and final file export output use identical render graph configurations and yield matching color representation.

## Mismatch Prevention Checkpoints

- [ ] **Dual Graph Validation**: Compare the RenderGraphDto built for preview against the RenderGraphDto built for export.
- [ ] **Color Pipeline Uniforms**: Ensure color management pipeline default inputs, working spaces, and transfer functions match between preview and export.
- [ ] **LUT Intensity Matching**: Verify that LUT intensity parameters match exactly, preventing differences between playback frames and exported video files.
- [ ] **Display vs. Output Color Transform**: Verify that the preview monitor displays through the correct preview display transform, while the file export encodes using the final output transform.
- [ ] **Telemetry Synchronicity**: Inspect native event emitters to verify that both preview and export render pipelines report identical pass counts.
