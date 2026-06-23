precision highp float;

const int NLE_PRIMARY_MODE_LINEAR = 0;
const int NLE_PRIMARY_MODE_LOG = 1;

uniform bool uPrimaryGradeEnabled;
uniform int uPrimaryGradeMode;
uniform float uPrimaryGradeIntensity;

uniform vec3 uLift;
uniform vec3 uGamma;
uniform vec3 uGain;
uniform vec3 uOffset;

uniform float uContrast;
uniform float uPivot;
uniform float uSaturation;

vec3 nleSafePowVec3(vec3 x, vec3 p) {
    return pow(max(x, vec3(0.0)), max(p, vec3(0.0001)));
}

float nleLuma709(vec3 c) {
    return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

vec3 nlePrimaryApplySaturation(vec3 color, float sat) {
    float luma = nleLuma709(color);
    return mix(vec3(luma), color, sat);
}

vec3 nleApplyContrastPivot(vec3 color, float contrast, float pivot) {
    return (color - vec3(pivot)) * contrast + vec3(pivot);
}

vec3 nlePrimaryLinear(vec3 color) {
    vec3 safeGamma = max(uGamma, vec3(0.0001));

    vec3 base = color * uGain +
        uLift * (vec3(1.0) - clamp(color, 0.0, 1.0)) +
        uOffset;

    vec3 graded = nleSafePowVec3(base, vec3(1.0) / safeGamma);

    graded = nleApplyContrastPivot(
        graded,
        uContrast,
        max(uPivot, 0.0001)
    );

    graded = nlePrimaryApplySaturation(
        graded,
        uSaturation
    );

    return graded;
}

float nleShadowWeight(float luma) {
    return 1.0 - smoothstep(0.0, 0.45, luma);
}

float nleMidWeight(float luma) {
    float up = smoothstep(0.05, 0.5, luma);
    float down = 1.0 - smoothstep(0.45, 0.95, luma);
    return up * down;
}

float nleHighlightWeight(float luma) {
    return smoothstep(0.35, 1.0, luma);
}

vec3 nlePrimaryLog(vec3 color) {
    float luma = nleLuma709(max(color, vec3(0.0)));

    float shadowW = nleShadowWeight(luma);
    float midW = nleMidWeight(luma);
    float highW = nleHighlightWeight(luma);

    vec3 safeGamma = max(uGamma, vec3(0.0001));

    vec3 graded = color;

    // Lift affects shadows more.
    graded += uLift * shadowW;

    // Offset affects the whole signal.
    graded += uOffset;

    // Gain affects highlights more.
    graded *= mix(vec3(1.0), uGain, highW);

    // Gamma affects midtones more.
    vec3 gammaCorrected = nleSafePowVec3(
        graded,
        vec3(1.0) / safeGamma
    );

    graded = mix(graded, gammaCorrected, midW);

    graded = nleApplyContrastPivot(
        graded,
        uContrast,
        max(uPivot, 0.0001)
    );

    graded = nlePrimaryApplySaturation(
        graded,
        uSaturation
    );

    return graded;
}

vec3 nleApplyPrimaryGrade(vec3 workingRgb) {
    if (!uPrimaryGradeEnabled || uPrimaryGradeIntensity <= 0.0) {
        return workingRgb;
    }

    vec3 original = workingRgb;
    vec3 graded = workingRgb;

    if (uPrimaryGradeMode == NLE_PRIMARY_MODE_LOG) {
        graded = nlePrimaryLog(workingRgb);
    } else {
        graded = nlePrimaryLinear(workingRgb);
    }

    return mix(original, graded, clamp(uPrimaryGradeIntensity, 0.0, 1.0));
}
