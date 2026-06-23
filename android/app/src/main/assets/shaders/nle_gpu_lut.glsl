precision highp float;

uniform bool uLutEnabled;
uniform bool uLutUse3dTexture;

uniform sampler3D uLut3dTexture;
uniform sampler2D uLut2dAtlasTexture;

uniform float uLutSize;
uniform float uLutIntensity;

vec3 nleSampleLut3d(vec3 color) {
    vec3 coord = clamp(color, 0.0, 1.0);

    // Center sampling prevents edge bias.
    float size = uLutSize;
    vec3 texCoord = (coord * (size - 1.0) + 0.5) / size;

    #if __VERSION__ >= 300
    return texture(uLut3dTexture, texCoord).rgb;
    #else
    return texture3D(uLut3dTexture, texCoord).rgb;
    #endif
}

vec3 nleSampleLut2dAtlasNearestLayer(vec3 color, float bIndex) {
    float size = uLutSize;

    float r = clamp(color.r, 0.0, 1.0) * (size - 1.0);
    float g = clamp(color.g, 0.0, 1.0) * (size - 1.0);

    float atlasWidth = size * size;
    float atlasHeight = size;

    float x = floor(r + 0.5) + bIndex * size;
    float y = floor(g + 0.5);

    vec2 uv = vec2(
        (x + 0.5) / atlasWidth,
        (y + 0.5) / atlasHeight
    );

    return texture2D(uLut2dAtlasTexture, uv).rgb;
}

vec3 nleSampleLut2dAtlasTrilinear(vec3 color) {
    float size = uLutSize;

    vec3 c = clamp(color, 0.0, 1.0) * (size - 1.0);

    float b0 = floor(c.b);
    float b1 = min(b0 + 1.0, size - 1.0);
    float bf = fract(c.b);

    vec3 c0 = vec3(c.r / (size - 1.0), c.g / (size - 1.0), b0 / (size - 1.0));
    vec3 c1 = vec3(c.r / (size - 1.0), c.g / (size - 1.0), b1 / (size - 1.0));

    vec3 lut0 = nleSampleLut2dAtlasNearestLayer(c0, b0);
    vec3 lut1 = nleSampleLut2dAtlasNearestLayer(c1, b1);

    return mix(lut0, lut1, bf);
}

vec3 nleApplyGpuLut(vec3 workingRgb) {
    if (!uLutEnabled || uLutIntensity <= 0.0) {
        return workingRgb;
    }

    vec3 inputColor = clamp(workingRgb, 0.0, 1.0);

    vec3 lutColor = uLutUse3dTexture
        ? nleSampleLut3d(inputColor)
        : nleSampleLut2dAtlasTrilinear(inputColor);

    return mix(workingRgb, lutColor, clamp(uLutIntensity, 0.0, 1.0));
}
