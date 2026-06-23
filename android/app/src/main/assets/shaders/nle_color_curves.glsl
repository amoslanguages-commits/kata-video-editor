precision highp float;

// Forward declarations of color management functions
vec3 nleLinearToSrgb3(vec3 c);
vec3 nleSrgbToLinear3(vec3 c);

// Curves uniforms
uniform bool uCurvesEnabled;
uniform int uEvaluationSpace; // 0 = Scene-Linear, 1 = Display-Referred

uniform sampler2D uRgbCurveTexture;
uniform sampler2D uHslCurveTextureA;
uniform sampler2D uHslCurveTextureB;

// Helper to calculate Rec. 709 Luminance
float nleCurvesLuma709(vec3 c) {
    return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

// Convert RGB to HSL
vec3 rgb2hsl(vec3 c) {
    float minVal = min(min(c.r, c.g), c.b);
    float maxVal = max(max(c.r, c.g), c.b);
    float delta = maxVal - minVal;

    float h = 0.0;
    float s = 0.0;
    float l = (maxVal + minVal) * 0.5;

    if (delta > 0.0) {
        if (l < 0.5) {
            s = delta / (maxVal + minVal + 1e-10);
        } else {
            s = delta / (2.0 - maxVal - minVal + 1e-10);
        }

        if (c.r == maxVal) {
            h = (c.g - c.b) / delta + (c.g < c.b ? 6.0 : 0.0);
        } else if (c.g == maxVal) {
            h = (c.b - c.r) / delta + 2.0;
        } else {
            h = (c.r - c.g) / delta + 4.0;
        }
        h /= 6.0;
    }

    return vec3(h, s, l);
}

// Helper for HSL to RGB conversion
float hue2rgb(float p, float q, float t) {
    if (t < 0.0) t += 1.0;
    if (t > 1.0) t -= 1.0;
    if (t < 1.0 / 6.0) return p + (q - p) * 6.0 * t;
    if (t < 1.0 / 2.0) return q;
    if (t < 2.0 / 3.0) return p + (q - p) * (2.0 / 3.0 - t) * 6.0;
    return p;
}

// Convert HSL to RGB
vec3 hsl2rgb(vec3 hsl) {
    float h = hsl.x;
    float s = hsl.y;
    float l = hsl.z;

    if (s == 0.0) {
        return vec3(l);
    }

    float q = l < 0.5 ? l * (1.0 + s) : l + s - l * s;
    float p = 2.0 * l - q;

    float r = hue2rgb(p, q, h + 1.0 / 3.0);
    float g = hue2rgb(p, q, h);
    float b = hue2rgb(p, q, h - 1.0 / 3.0);

    return vec3(r, g, b);
}

vec3 nleApplyColorCurvesInternal(vec3 rgb) {
    // 1. Apply RGB curves (Individual channels first, then Master)
    float rGraded = texture2D(uRgbCurveTexture, vec2(rgb.r, 0.5)).g; // Red curve
    float gGraded = texture2D(uRgbCurveTexture, vec2(rgb.g, 0.5)).b; // Green curve
    float bGraded = texture2D(uRgbCurveTexture, vec2(rgb.b, 0.5)).a; // Blue curve

    vec3 gradedRgb = vec3(rGraded, gGraded, bGraded);

    gradedRgb.r = texture2D(uRgbCurveTexture, vec2(gradedRgb.r, 0.5)).r; // Master curve
    gradedRgb.g = texture2D(uRgbCurveTexture, vec2(gradedRgb.g, 0.5)).r;
    gradedRgb.b = texture2D(uRgbCurveTexture, vec2(gradedRgb.b, 0.5)).r;

    // 2. Apply Luma Curve (Remapping luminance while preserving color ratio)
    float originalLuma = nleCurvesLuma709(gradedRgb);
    float newLuma = texture2D(uHslCurveTextureB, vec2(originalLuma, 0.5)).g; // Luma is in G channel of Texture B
    
    if (originalLuma > 0.0001) {
        gradedRgb = gradedRgb * (newLuma / originalLuma);
    } else {
        gradedRgb = vec3(newLuma);
    }

    // 3. Apply HSL Curves
    vec3 hsl = rgb2hsl(gradedRgb);

    // Sample HSL curves:
    // uHslCurveTextureA channels:
    // R: hueVsSat, G: hueVsHue, B: hueVsLum, A: lumVsSat
    vec4 hslSampleA = texture2D(uHslCurveTextureA, vec2(hsl.x, 0.5)); // Input: Hue
    float y_hueVsSat = hslSampleA.r;
    float y_hueVsHue = hslSampleA.g;
    float y_hueVsLum = hslSampleA.b;

    // uHslCurveTextureB channels:
    // R: satVsSat, G: luma (handled), B: 0.0, A: 1.0
    vec4 hslSampleB = texture2D(uHslCurveTextureB, vec2(hsl.y, 0.5)); // Input: Saturation
    float y_satVsSat = hslSampleB.r;

    // Sample for Lum vs Sat
    vec4 hslSampleA_lum = texture2D(uHslCurveTextureA, vec2(hsl.z, 0.5)); // Input: Luma
    float y_lumVsSat = hslSampleA_lum.a;

    // Apply offsets: evaluated_y - input_x
    // Hue vs Hue offset
    float hueOffset = y_hueVsHue - hsl.x;
    hsl.x = fract(hsl.x + hueOffset);

    // Saturation curves offsets combined: Hue vs Sat, Lum vs Sat, Sat vs Sat
    float satOffset = (y_hueVsSat - hsl.x) + (y_lumVsSat - hsl.z) + (y_satVsSat - hsl.y);
    hsl.y = clamp(hsl.y + satOffset, 0.0, 1.0);

    // Hue vs Lum offset
    float lumOffset = y_hueVsLum - hsl.x;
    hsl.z = clamp(hsl.z + lumOffset, 0.0, 1.0);

    // Convert back to RGB
    return hsl2rgb(hsl);
}

vec3 nleApplyColorCurves(vec3 workingRgb) {
    if (!uCurvesEnabled) {
        return workingRgb;
    }

    if (uEvaluationSpace == 1) {
        // Display-referred: decode to sRGB display range first, apply curves, then encode back to scene-linear.
        vec3 disp = nleLinearToSrgb3(workingRgb);
        vec3 gradedDisp = nleApplyColorCurvesInternal(disp);
        return nleSrgbToLinear3(gradedDisp);
    } else {
        // Scene-linear: apply directly
        return nleApplyColorCurvesInternal(workingRgb);
    }
}
