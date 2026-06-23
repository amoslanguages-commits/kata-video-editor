precision highp float;

// Uniforms for HSL qualifier ranges
uniform bool uQualifierEnabled;
uniform float uHueCenter;
uniform float uHueWidth;
uniform float uHueSoftness;

uniform float uSatCenter;
uniform float uSatWidth;
uniform float uSatSoftness;

uniform float uLumCenter;
uniform float uLumWidth;
uniform float uLumSoftness;

uniform float uCleanBlack;
uniform float uCleanWhite;
uniform float uBlur;
uniform bool uInvert;
uniform int uViewMode; // 0 = Normal, 1 = Matte, 2 = Overlay

// Uniforms for secondary grading correction
uniform bool uCorrectionEnabled;
uniform float uSecondaryGradeIntensity;
uniform float uExposure;
uniform float uContrast;
uniform float uSaturation;
uniform float uTemperature;
uniform float uTint;
uniform float uLift;
uniform float uGamma;
uniform float uGain;
uniform float uOffset;

// Texture size for texel offsets (blur)
uniform vec2 uTextureSize;

vec3 nleSecondaryRgb2Hsl(vec3 c) {
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

float nleSecondaryRangeMask(float value, float center, float width, float softness, bool circular) {
    if (width >= 1.0) {
        return 1.0;
    }
    float d = abs(value - center);
    if (circular && d > 0.5) {
        d = 1.0 - d;
    }
    float halfW = width * 0.5;
    float s = max(softness, 0.0001);
    return 1.0 - smoothstep(halfW, halfW + s, d);
}

float nleSecondaryCleanMask(float mask, float cleanBlack, float cleanWhite) {
    float low = cleanBlack;
    float high = 1.0 - cleanWhite;
    if (high <= low) {
        return mask > low ? 1.0 : 0.0;
    }
    return clamp((mask - low) / (high - low), 0.0, 1.0);
}

float nleSecondaryGetMaskAt(sampler2D tex, vec2 coord) {
    if (!uQualifierEnabled) {
        return 1.0;
    }
    vec3 color = texture2D(tex, coord).rgb;
    vec3 hsl = nleSecondaryRgb2Hsl(color);
    float mh = nleSecondaryRangeMask(hsl.x, uHueCenter, uHueWidth, uHueSoftness, true);
    float ms = nleSecondaryRangeMask(hsl.y, uSatCenter, uSatWidth, uSatSoftness, false);
    float ml = nleSecondaryRangeMask(hsl.z, uLumCenter, uLumWidth, uLumSoftness, false);
    float m = mh * ms * ml;
    return nleSecondaryCleanMask(m, uCleanBlack, uCleanWhite);
}

float nleSecondaryLuma709(vec3 c) {
    return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

vec3 nleSecondaryApplySaturation(vec3 color, float sat) {
    float luma = nleSecondaryLuma709(color);
    return mix(vec3(luma), color, sat);
}

vec3 nleSecondaryApplyContrastPivot(vec3 color, float contrast, float pivot) {
    return (color - vec3(pivot)) * contrast + vec3(pivot);
}

vec3 nleSecondarySafePowVec3(vec3 x, vec3 p) {
    return pow(max(x, vec3(0.0)), max(p, vec3(0.0001)));
}

vec3 nleSecondaryApplyPrimaryGrade(vec3 workingRgb) {
    if (!uCorrectionEnabled) {
        return workingRgb;
    }

    // 1. Exposure
    vec3 graded = workingRgb * pow(2.0, uExposure);

    // 2. Temperature and Tint
    graded = nleApplyTemperatureTint(graded, uTemperature, uTint);

    // 3. Lift / Gamma / Gain / Offset (similar to primary linear grade)
    vec3 safeGamma = vec3(max(uGamma, 0.0001));
    vec3 safeGain = vec3(max(uGain, 0.0001));
    vec3 base = graded * safeGain +
        vec3(uLift) * (vec3(1.0) - clamp(graded, 0.0, 1.0)) +
        vec3(uOffset);

    graded = nleSecondarySafePowVec3(base, vec3(1.0) / safeGamma);

    // 4. Contrast
    graded = nleSecondaryApplyContrastPivot(graded, uContrast, 0.5);

    // 5. Saturation
    graded = nleSecondaryApplySaturation(graded, uSaturation);

    return graded;
}
