# 31A-QA: Shader Compilation Safety Checklist

This checklist targets driver compatibility issues across different GPU venders (ARM Mali, Qualcomm Adreno, Apple GPU) during GLSL compile steps.

## Shader Code Safety Guidelines

- [ ] **Precision Qualifiers**: Ensure all fragment shaders declare a default precision qualifier (`precision mediump float;`) at the top of the shader file.
- [ ] **Varying Variable Alignment**: Ensure all `varying` variable names, types, and precision match exactly between vertex and fragment shaders.
- [ ] **Sampler Allocation**: Never declare or bind texture samplers inside loops or conditional blocks. Declaring `uniform sampler2D` must happen at the global scope.
- [ ] **Type Cast Rigor**: Avoid implicit conversions (e.g. `vec3 color = 1.0;` is invalid; write `vec3 color = vec3(1.0);`).
- [ ] **Array Bounds Indexing**: Only access array elements with constant-expression indices (required by GLES 2.0 specs).

## Compilation Smoke Tests
- [ ] **Compile Test**: Program compiling step must return non-zero vertex/fragment shader handles.
- [ ] **Link Test**: Program linking step must return non-zero program handle.
- [ ] **Static Diagnostics**: Syntax verification run must be integrated into `NleShaderCompileSmokeTester` so we receive clear compiler errors in the reports rather than native app crashes.
