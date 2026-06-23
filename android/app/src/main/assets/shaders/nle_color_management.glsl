// =============================================================================
// nle_color_management.glsl
//
// 30A-PRO: Industry Color Management — GLSL Function Library
//
// Include this file in your layer/compositor shader before main().
// It provides:
//   • sRGB / Rec.709 / Gamma-2.2/2.4 EOTF (decode) and OETF (encode)
//   • Log profiles: LogC, S-Log3, C-Log3, V-Log  (log → scene-linear)
//   • HLG and PQ (HDR) transfer functions
//   • Scene-linear gamut transforms (Rec.709 ↔ Rec.2020 ↔ ACEScg)
//   • Exposure, contrast, saturation in scene-linear space
//   • Tone-mapping: simple Reinhard, ACES approx, Hable
//   • Utility: luma, clamp, lerp
//
// All functions operate on vec3 linear-light RGB unless noted.
// All inputs are assumed to be in the [0,1] display range before decode.
// =============================================================================

#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif

// =============================================================================
// CONSTANTS
// =============================================================================

#define NLE_PI          3.14159265358979323846
#define NLE_E           2.71828182845904523536
#define NLE_LOG2E       1.44269504088896340736
#define NLE_LN2         0.69314718055994530941

// sRGB primary luminance weights (Rec. 709)
#define NLE_LUM_R 0.2126
#define NLE_LUM_G 0.7152
#define NLE_LUM_B 0.0722

// =============================================================================
// UTILITY
// =============================================================================

float nleLuma(vec3 c) {
    return dot(c, vec3(NLE_LUM_R, NLE_LUM_G, NLE_LUM_B));
}

vec3 nleClamp01(vec3 c) {
    return clamp(c, 0.0, 1.0);
}

float nleSafe(float x) {
    return max(x, 0.0);
}

vec3 nleSafe3(vec3 c) {
    return max(c, vec3(0.0));
}

// Power function that preserves sign (used for gamma curves on negative values)
float nleSignedPow(float x, float p) {
    return sign(x) * pow(abs(x), p);
}

// =============================================================================
// TRANSFER CURVE DECODE (display-encoded → scene-linear)
// =============================================================================

// ---- sRGB EOTF ----
float nleSrgbToLinear(float v) {
    return (v <= 0.04045)
        ? (v / 12.92)
        : pow((v + 0.055) / 1.055, 2.4);
}

vec3 nleSrgbToLinear3(vec3 c) {
    return vec3(
        nleSrgbToLinear(c.r),
        nleSrgbToLinear(c.g),
        nleSrgbToLinear(c.b)
    );
}

// ---- sRGB OETF (linear → sRGB) ----
float nleLinearToSrgb(float v) {
    float v2 = nleSafe(v);
    return (v2 <= 0.0031308)
        ? (12.92 * v2)
        : (1.055 * pow(v2, 1.0 / 2.4) - 0.055);
}

vec3 nleLinearToSrgb3(vec3 c) {
    return vec3(
        nleLinearToSrgb(c.r),
        nleLinearToSrgb(c.g),
        nleLinearToSrgb(c.b)
    );
}

// ---- Rec.709 EOTF ----
// IEC 61966-2-4 extended Rec.709 (identical to sRGB curve with 2.2 knee)
float nleRec709ToLinear(float v) {
    return (v < 0.081)
        ? (v / 4.5)
        : pow((v + 0.099) / 1.099, 1.0 / 0.45);
}

vec3 nleRec709ToLinear3(vec3 c) {
    return vec3(
        nleRec709ToLinear(c.r),
        nleRec709ToLinear(c.g),
        nleRec709ToLinear(c.b)
    );
}

// ---- Rec.709 OETF ----
float nleLinearToRec709(float v) {
    float v2 = nleSafe(v);
    return (v2 < 0.018)
        ? (4.5 * v2)
        : (1.099 * pow(v2, 0.45) - 0.099);
}

vec3 nleLinearToRec709_3(vec3 c) {
    return vec3(
        nleLinearToRec709(c.r),
        nleLinearToRec709(c.g),
        nleLinearToRec709(c.b)
    );
}

// ---- Gamma 2.2 ----
vec3 nleGamma22ToLinear(vec3 c) {
    return pow(nleSafe3(c), vec3(2.2));
}

vec3 nleLinearToGamma22(vec3 c) {
    return pow(nleSafe3(c), vec3(1.0 / 2.2));
}

// ---- Gamma 2.4 ----
vec3 nleGamma24ToLinear(vec3 c) {
    return pow(nleSafe3(c), vec3(2.4));
}

vec3 nleLinearToGamma24(vec3 c) {
    return pow(nleSafe3(c), vec3(1.0 / 2.4));
}

// =============================================================================
// LOG PROFILE DECODE (log-encoded → scene-linear)
// =============================================================================

// ---- ARRI LogC3 (EI800) → scene-linear ----
// LogC encoding parameters for EI800
#define NLE_LOGC_CUT    0.010591
#define NLE_LOGC_A      5.555556
#define NLE_LOGC_B      0.052272
#define NLE_LOGC_C      0.247190
#define NLE_LOGC_D      0.385537
#define NLE_LOGC_E      5.367655
#define NLE_LOGC_F      0.092809

float nleLogCToLinear(float v) {
    if (v > NLE_LOGC_E * NLE_LOGC_CUT + NLE_LOGC_F) {
        return (pow(10.0, (v - NLE_LOGC_D) / NLE_LOGC_C) - NLE_LOGC_B) / NLE_LOGC_A;
    } else {
        return (v - NLE_LOGC_F) / NLE_LOGC_E;
    }
}

vec3 nleLogCToLinear3(vec3 c) {
    return vec3(
        nleLogCToLinear(c.r),
        nleLogCToLinear(c.g),
        nleLogCToLinear(c.b)
    );
}

// ---- Sony S-Log3 → scene-linear ----
#define NLE_SLOG3_A  0.432699
#define NLE_SLOG3_B  0.616596
#define NLE_SLOG3_C  0.030001222851889
#define NLE_SLOG3_D  171.2102946929
#define NLE_SLOG3_E  3.53881278538813

float nleSlog3ToLinear(float v) {
    if (v >= 0.171 * NLE_SLOG3_A + 0.03) {
        return pow(10.0, (v - NLE_SLOG3_B) / NLE_SLOG3_A) * NLE_SLOG3_D - NLE_SLOG3_D;
    } else {
        return (v - NLE_SLOG3_C) / NLE_SLOG3_E;
    }
}

vec3 nleSlog3ToLinear3(vec3 c) {
    return vec3(
        nleSlog3ToLinear(c.r),
        nleSlog3ToLinear(c.g),
        nleSlog3ToLinear(c.b)
    );
}

// ---- Canon C-Log3 → scene-linear ----
float nleClog3ToLinear(float v) {
    if (v < 0.04076162) {
        return -(pow(10.0, (0.07623209 - v) / 0.42889912) - 1.0) / 14.98325;
    } else if (v <= 0.105357102) {
        return (v - 0.073059361) / 2.3069815;
    } else {
        return (pow(10.0, (v - 0.069886632) / 0.42889912) - 1.0) / 14.98325;
    }
}

vec3 nleClog3ToLinear3(vec3 c) {
    return vec3(
        nleClog3ToLinear(c.r),
        nleClog3ToLinear(c.g),
        nleClog3ToLinear(c.b)
    );
}

// ---- Panasonic V-Log → scene-linear ----
#define NLE_VLOG_CUT1    0.01
#define NLE_VLOG_CUT2    0.181
#define NLE_VLOG_B       0.00873
#define NLE_VLOG_C       0.241514
#define NLE_VLOG_D       0.598206

float nleVLogToLinear(float v) {
    if (v < NLE_VLOG_CUT2) {
        return (v - NLE_VLOG_B) / 5.6;
    } else {
        return pow(10.0, (v - NLE_VLOG_D) / NLE_VLOG_C) - NLE_VLOG_B;
    }
}

vec3 nleVLogToLinear3(vec3 c) {
    return vec3(
        nleVLogToLinear(c.r),
        nleVLogToLinear(c.g),
        nleVLogToLinear(c.b)
    );
}

// =============================================================================
// HDR TRANSFER CURVES
// =============================================================================

// ---- HLG (Hybrid Log-Gamma) EOTF — ITU-R BT.2100 ----
// Scene-light HLG → scene-linear relative scene luminance
#define NLE_HLG_A 0.17883277
#define NLE_HLG_B 0.28466892
#define NLE_HLG_C 0.55991073

float nleHlgToLinear(float v) {
    if (v <= 0.5) {
        return (v * v) / 3.0;
    } else {
        return (exp((v - NLE_HLG_C) / NLE_HLG_A) + NLE_HLG_B) / 12.0;
    }
}

vec3 nleHlgToLinear3(vec3 c) {
    return vec3(
        nleHlgToLinear(c.r),
        nleHlgToLinear(c.g),
        nleHlgToLinear(c.b)
    );
}

// ---- HLG OETF (linear → HLG) ----
float nleLinearToHlg(float v) {
    float v2 = nleSafe(v);
    if (v2 <= 1.0 / 12.0) {
        return sqrt(3.0 * v2);
    } else {
        return NLE_HLG_A * log(12.0 * v2 - NLE_HLG_B) + NLE_HLG_C;
    }
}

vec3 nleLinearToHlg3(vec3 c) {
    return vec3(
        nleLinearToHlg(c.r),
        nleLinearToHlg(c.g),
        nleLinearToHlg(c.b)
    );
}

// ---- PQ (Perceptual Quantizer) EOTF — SMPTE ST 2084 ----
// Normalized signal [0,1] → normalized scene-linear (relative to 10,000 nits)
#define NLE_PQ_M1 0.1593017578125
#define NLE_PQ_M2 78.84375
#define NLE_PQ_C1 0.8359375
#define NLE_PQ_C2 18.8515625
#define NLE_PQ_C3 18.6875

float nlePqToLinear(float v) {
    float v2 = nleSafe(v);
    float num = max(pow(v2, 1.0 / NLE_PQ_M2) - NLE_PQ_C1, 0.0);
    float den = NLE_PQ_C2 - NLE_PQ_C3 * pow(v2, 1.0 / NLE_PQ_M2);
    return pow(num / den, 1.0 / NLE_PQ_M1);
}

vec3 nlePqToLinear3(vec3 c) {
    return vec3(
        nlePqToLinear(c.r),
        nlePqToLinear(c.g),
        nlePqToLinear(c.b)
    );
}

// ---- PQ OETF (linear → PQ) ----
float nleLinearToPq(float v) {
    float v2 = nleSafe(v);
    float xm1 = pow(v2, NLE_PQ_M1);
    return pow(
        (NLE_PQ_C1 + NLE_PQ_C2 * xm1) / (1.0 + NLE_PQ_C3 * xm1),
        NLE_PQ_M2
    );
}

vec3 nleLinearToPq3(vec3 c) {
    return vec3(
        nleLinearToPq(c.r),
        nleLinearToPq(c.g),
        nleLinearToPq(c.b)
    );
}

// =============================================================================
// GAMUT TRANSFORMS (3×3 matrix multiply)
// =============================================================================

// ---- Rec.709 → Rec.2020 ----
vec3 nleRec709ToRec2020(vec3 c) {
    return vec3(
        dot(c, vec3(0.6274040, 0.3292820, 0.0433136)),
        dot(c, vec3(0.0690970, 0.9195400, 0.0113612)),
        dot(c, vec3(0.0163916, 0.0880132, 0.8955950))
    );
}

// ---- Rec.2020 → Rec.709 ----
vec3 nleRec2020ToRec709(vec3 c) {
    return vec3(
        dot(c, vec3( 1.6604910, -0.5876411, -0.0728499)),
        dot(c, vec3(-0.1245505,  1.1328999, -0.0083494)),
        dot(c, vec3(-0.0181508, -0.1005789,  1.1187297))
    );
}

// ---- Rec.709 → ACEScg (AP1) ----
vec3 nleRec709ToAcesCg(vec3 c) {
    return vec3(
        dot(c, vec3(0.6131324, 0.3395356, 0.0474969)),
        dot(c, vec3(0.0701243, 0.9163989, 0.0134772)),
        dot(c, vec3(0.0205990, 0.1094891, 0.8699120))
    );
}

// ---- ACEScg (AP1) → Rec.709 ----
vec3 nleAcesCgToRec709(vec3 c) {
    return vec3(
        dot(c, vec3( 1.7048586, -0.6217159, -0.0832077)),
        dot(c, vec3(-0.1300571,  1.1407308, -0.0108972)),
        dot(c, vec3(-0.0239504, -0.1289706,  1.1536932))
    );
}

// ---- Rec.709 → Display P3 ----
vec3 nleRec709ToDisplayP3(vec3 c) {
    return vec3(
        dot(c, vec3(0.8224621, 0.1775379, 0.0000000)),
        dot(c, vec3(0.0331941, 0.9668059, 0.0000000)),
        dot(c, vec3(0.0170827, 0.0723974, 0.9105199))
    );
}

// ---- Display P3 → Rec.709 ----
vec3 nleDisplayP3ToRec709(vec3 c) {
    return vec3(
        dot(c, vec3( 1.2249402, -0.2249402, 0.0000000)),
        dot(c, vec3(-0.0420759,  1.0420759, 0.0000000)),
        dot(c, vec3(-0.0196240, -0.0786534, 1.0982774))
    );
}

// =============================================================================
// SCENE-LINEAR GRADING OPERATIONS
// =============================================================================

// ---- Exposure (stops) ----
// Apply in scene-linear space.  0 = no change, +1 = 1 stop brighter.
vec3 nleApplyExposure(vec3 c, float exposureStops) {
    return c * pow(2.0, exposureStops);
}

// ---- Contrast around mid-grey (0.18) ----
// pivot = 0.18 scene-linear.  contrast=1 → no change.
vec3 nleApplyContrast(vec3 c, float contrast) {
    const float pivot = 0.18;
    return pivot + (c - pivot) * contrast;
}

// ---- Saturation (luma-weighted, scene-linear) ----
// saturation=1 → no change.  0 → greyscale.  >1 → hypersaturate.
vec3 nleApplySaturation(vec3 c, float saturation) {
    float lum = nleLuma(c);
    return lum + (c - lum) * saturation;
}

// ---- Lift / Gamma / Gain (DaVinci-style primary correction) ----
// All three are vec3 (RGB triplets).
// Lift offset: default (0,0,0). Gamma: default (1,1,1). Gain: default (1,1,1).
vec3 nleApplyLiftGammaGain(
    vec3 c,
    vec3 lift,
    vec3 gamma,
    vec3 gain,
    vec3 offset
) {
    // Apply in scene-linear space.
    // Lift raises/lowers blacks; Gain scales whites; Gamma is midtone power.
    vec3 x = c * gain + lift + offset;
    // Avoid pow of negative values by clamping before gamma
    x = max(x, vec3(0.0));
    // gamma is a multiplicative power — 1.0 = neutral
    // store as "1/gamma" so user value > 1 brightens mids
    vec3 gammaInv = vec3(1.0) / max(gamma, vec3(0.001));
    return pow(x, gammaInv);
}

// ---- Temperature / Tint (in scene-linear Rec.709) ----
// temperature: negative = cool (blue), positive = warm (orange). Range: -1 to +1.
// tint: negative = green, positive = magenta. Range: -1 to +1.
vec3 nleApplyTemperatureTint(vec3 c, float temperature, float tint) {
    // Simplified chromatic adaptation in display-referred linear space.
    // Scale factors derived from standard D65 → target white point offsets.
    float warmR = 1.0 + temperature * 0.2;
    float warmB = 1.0 - temperature * 0.2;
    float tintG = 1.0 - tint * 0.1;
    float tintRB = 1.0 + tint * 0.05;
    return vec3(c.r * warmR * tintRB, c.g * tintG, c.b * warmB * tintRB);
}

// ---- Highlights / Shadows (zone-selective luminance) ----
// highlights: positive raises bright areas. Range: -1 to +1.
// shadows: positive raises dark areas. Range: -1 to +1.
vec3 nleApplyHighlightsShadows(vec3 c, float highlights, float shadows) {
    float lum = nleLuma(c);
    // Highlights mask — peaks at lum=1, zero at lum=0
    float hMask = lum * lum;
    // Shadows mask — peaks at lum=0, zero at lum=1
    float sMask = (1.0 - lum) * (1.0 - lum);
    float delta = highlights * hMask * 0.5 + shadows * sMask * 0.5;
    return c + delta;
}

// =============================================================================
// TONE MAPPING
// =============================================================================

// ---- Simple Reinhard ----
vec3 nleToneMapReinhard(vec3 c) {
    return c / (c + vec3(1.0));
}

// ---- ACES Filmic approximation (Krzysztof Narkowicz) ----
vec3 nleToneMapAcesApprox(vec3 c) {
    const float a = 2.51;
    const float b = 0.03;
    const float cc = 2.43;
    const float d = 0.59;
    const float e = 0.14;
    return clamp((c * (a * c + b)) / (c * (cc * c + d) + e), 0.0, 1.0);
}

// ---- Hable / Uncharted 2 ----
vec3 _nleHableOp(vec3 x) {
    const float A = 0.15, B = 0.50, C = 0.10, D = 0.20, E = 0.02, F = 0.30;
    return ((x * (A * x + C * B) + D * E) / (x * (A * x + B) + D * F)) - E / F;
}

vec3 nleToneMapHable(vec3 c) {
    const float W = 11.2; // linear white point
    vec3 curr = _nleHableOp(c * 2.0);
    vec3 whiteScale = vec3(1.0) / _nleHableOp(vec3(W));
    return curr * whiteScale;
}

// =============================================================================
// DECODE / ENCODE DISPATCHERS
// =============================================================================

// Transfer curve IDs (must match NleTransferCurve Dart enum index order)
#define NLE_TC_AUTO     0
#define NLE_TC_LINEAR   1
#define NLE_TC_SRGB     2
#define NLE_TC_REC709   3
#define NLE_TC_GAMMA22  4
#define NLE_TC_GAMMA24  5
#define NLE_TC_LOGC     6
#define NLE_TC_SLOG3    7
#define NLE_TC_CLOG3    8
#define NLE_TC_VLOG     9
#define NLE_TC_HLG      10
#define NLE_TC_PQ       11

// Decode a signal-encoded pixel to scene-linear.
// tcId should be passed as a uniform int from the Dart side.
vec3 nleDecodeTransferCurve(vec3 c, int tcId) {
    if (tcId == NLE_TC_SRGB || tcId == NLE_TC_AUTO) {
        return nleSrgbToLinear3(c);
    } else if (tcId == NLE_TC_REC709) {
        return nleRec709ToLinear3(c);
    } else if (tcId == NLE_TC_GAMMA22) {
        return nleGamma22ToLinear(c);
    } else if (tcId == NLE_TC_GAMMA24) {
        return nleGamma24ToLinear(c);
    } else if (tcId == NLE_TC_LOGC) {
        return nleLogCToLinear3(c);
    } else if (tcId == NLE_TC_SLOG3) {
        return nleSlog3ToLinear3(c);
    } else if (tcId == NLE_TC_CLOG3) {
        return nleClog3ToLinear3(c);
    } else if (tcId == NLE_TC_VLOG) {
        return nleVLogToLinear3(c);
    } else if (tcId == NLE_TC_HLG) {
        return nleHlgToLinear3(c);
    } else if (tcId == NLE_TC_PQ) {
        return nlePqToLinear3(c);
    } else { // NLE_TC_LINEAR
        return c;
    }
}

// Output transfer curve IDs (must match NleOutputTransferCurve Dart enum)
#define NLE_OTC_SRGB    0
#define NLE_OTC_REC709  1
#define NLE_OTC_GAMMA24 2
#define NLE_OTC_HLG     3
#define NLE_OTC_PQ      4

// Encode scene-linear to display-referred signal.
vec3 nleEncodeTransferCurve(vec3 c, int tcId) {
    if (tcId == NLE_OTC_SRGB) {
        return nleLinearToSrgb3(c);
    } else if (tcId == NLE_OTC_REC709) {
        return nleLinearToRec709_3(c);
    } else if (tcId == NLE_OTC_GAMMA24) {
        return nleLinearToGamma24(c);
    } else if (tcId == NLE_OTC_HLG) {
        return nleLinearToHlg3(c);
    } else if (tcId == NLE_OTC_PQ) {
        return nleLinearToPq3(c);
    } else {
        return c; // linear passthrough
    }
}

// Tone-map IDs (must match NleToneMapMode Dart enum)
#define NLE_TM_NONE     0
#define NLE_TM_REINHARD 1
#define NLE_TM_ACES     2
#define NLE_TM_HABLE    3

vec3 nleToneMap(vec3 c, int tmId) {
    if (tmId == NLE_TM_REINHARD) {
        return nleToneMapReinhard(c);
    } else if (tmId == NLE_TM_ACES) {
        return nleToneMapAcesApprox(c);
    } else if (tmId == NLE_TM_HABLE) {
        return nleToneMapHable(c);
    } else {
        return c; // NLE_TM_NONE
    }
}

// =============================================================================
// FULL COLOR PIPELINE FUNCTION
//
// Usage in your compositor fragment shader:
//
//   uniform int u_inputTransferCurve;    // NleTransferCurve enum index
//   uniform int u_outputTransferCurve;   // NleOutputTransferCurve enum index
//   uniform int u_toneMapMode;           // NleToneMapMode enum index
//   uniform float u_exposure;
//   uniform float u_contrast;
//   uniform float u_saturation;
//   uniform float u_temperature;
//   uniform float u_tint;
//   uniform float u_highlights;
//   uniform float u_shadows;
//   uniform vec3 u_lift;
//   uniform vec3 u_gamma;
//   uniform vec3 u_gain;
//   uniform vec3 u_offset;
//   uniform float u_outputBlackLevel;
//   uniform float u_outputWhiteLevel;
//
//   // In main():
//   vec4 src = texture2D(u_texture, v_texCoord);
//   vec3 graded = nleApplyFullPipeline(src.rgb, ...);
//   gl_FragColor = vec4(graded, src.a);
//
// =============================================================================

vec3 nleApplyFullPipeline(
    vec3 srcEncoded,
    int inputTcId,
    float exposure,
    float contrast,
    float saturation,
    float temperature,
    float tint,
    float highlights,
    float shadows,
    vec3 lift,
    vec3 gamma,
    vec3 gain,
    vec3 offset,
    int toneMapId,
    float outputBlackLevel,
    float outputWhiteLevel,
    int outputTcId
) {
    // 1. Decode input transfer curve → scene-linear
    vec3 lin = nleDecodeTransferCurve(srcEncoded, inputTcId);

    // 2. Exposure (stops, in scene-linear)
    lin = nleApplyExposure(lin, exposure);

    // 3. Primary Lift / Gamma / Gain
    lin = nleApplyLiftGammaGain(lin, lift, gamma, gain, offset);

    // 4. Contrast (around 0.18 grey)
    lin = nleApplyContrast(lin, contrast);

    // 5. Saturation
    lin = nleApplySaturation(lin, saturation);

    // 6. Temperature / Tint
    lin = nleApplyTemperatureTint(lin, temperature, tint);

    // 7. Highlights / Shadows
    lin = nleApplyHighlightsShadows(lin, highlights, shadows);

    // 8. Tone mapping (for HDR → SDR or artistic look)
    lin = nleToneMap(lin, toneMapId);

    // 9. Output level scaling
    lin = lin * (outputWhiteLevel - outputBlackLevel) + outputBlackLevel;

    // 10. Clamp to valid range before encoding
    lin = nleClamp01(lin);

    // 11. Encode output transfer curve → display signal
    return nleEncodeTransferCurve(lin, outputTcId);
}

// =============================================================================
// 30B-PRO: SCENE-LINEAR / FLOATING-POINT GPU PIPELINE UNIFORMS & HELPERS
// =============================================================================

uniform int u_inputTransferCurve;
uniform float u_exposureBias;
uniform int u_inputColorSpace;
uniform int u_workingColorSpace;

uniform int u_outputColorSpace;
uniform int u_toneMapMode;
uniform float u_outputBlackLevel;
uniform float u_outputWhiteLevel;
uniform int u_outputTransferCurve;
uniform int u_enableDither;

#define NLE_CS_AUTO       0
#define NLE_CS_SRGB       1
#define NLE_CS_REC709     2
#define NLE_CS_DISPLAY_P3 3
#define NLE_CS_REC2020    4
#define NLE_CS_ACES_CG    5
#define NLE_CS_ACES_2065  6
#define NLE_CS_CAMERA_LOG 7

#define NLE_WCS_LINEAR_SRGB   0
#define NLE_WCS_LINEAR_REC709 1
#define NLE_WCS_ACES_CG       2

#define NLE_OCS_REC709     0
#define NLE_OCS_SRGB       1
#define NLE_OCS_DISPLAY_P3 2
#define NLE_OCS_REC2020    3

vec3 nleConvertColorSpace(vec3 c, int fromSpace, int toSpace) {
    if (fromSpace == toSpace) {
        return c;
    }

    // 1. Convert input space to Rec709 (reference)
    vec3 rec709 = c;
    if (fromSpace == NLE_CS_SRGB || fromSpace == NLE_CS_REC709 || fromSpace == NLE_CS_AUTO) {
        rec709 = c;
    } else if (fromSpace == NLE_CS_DISPLAY_P3) {
        rec709 = nleDisplayP3ToRec709(c);
    } else if (fromSpace == NLE_CS_REC2020) {
        rec709 = nleRec2020ToRec709(c);
    } else if (fromSpace == NLE_CS_ACES_CG) {
        rec709 = nleAcesCgToRec709(c);
    }

    // 2. Convert from Rec709 to target space
    vec3 target = rec709;
    if (toSpace == NLE_CS_SRGB || toSpace == NLE_CS_REC709 || toSpace == NLE_CS_AUTO || toSpace == NLE_WCS_LINEAR_SRGB || toSpace == NLE_WCS_LINEAR_REC709 || toSpace == NLE_OCS_REC709 || toSpace == NLE_OCS_SRGB) {
        target = rec709;
    } else if (toSpace == NLE_CS_DISPLAY_P3 || toSpace == NLE_OCS_DISPLAY_P3) {
        target = nleRec709ToDisplayP3(rec709);
    } else if (toSpace == NLE_CS_REC2020 || toSpace == NLE_OCS_REC2020) {
        target = nleRec709ToRec2020(rec709);
    } else if (toSpace == NLE_CS_ACES_CG || toSpace == NLE_WCS_ACES_CG) {
        target = nleRec709ToAcesCg(rec709);
    }

    return target;
}

vec3 nleColorManageToWorking(vec3 rgb) {
    vec3 lin = nleDecodeTransferCurve(rgb, u_inputTransferCurve);
    lin = nleApplyExposure(lin, u_exposureBias);

    int toSpace = NLE_CS_REC709;
    if (u_workingColorSpace == NLE_WCS_ACES_CG) {
        toSpace = NLE_CS_ACES_CG;
    }
    return nleConvertColorSpace(lin, u_inputColorSpace, toSpace);
}

vec3 nleColorManageToOutput(vec3 rgb, vec2 fragCoord) {
    int fromSpace = NLE_CS_REC709;
    if (u_workingColorSpace == NLE_WCS_ACES_CG) {
        fromSpace = NLE_CS_ACES_CG;
    }

    int toSpace = NLE_CS_REC709;
    if (u_outputColorSpace == NLE_OCS_SRGB) {
        toSpace = NLE_CS_SRGB;
    } else if (u_outputColorSpace == NLE_OCS_DISPLAY_P3) {
        toSpace = NLE_CS_DISPLAY_P3;
    } else if (u_outputColorSpace == NLE_OCS_REC2020) {
        toSpace = NLE_CS_REC2020;
    }

    vec3 lin = nleConvertColorSpace(rgb, fromSpace, toSpace);
    lin = nleToneMap(lin, u_toneMapMode);
    lin = lin * (u_outputWhiteLevel - u_outputBlackLevel) + u_outputBlackLevel;
    lin = nleClamp01(lin);

    vec3 encoded = nleEncodeTransferCurve(lin, u_outputTransferCurve);

    if (u_enableDither > 0) {
        float noise = (fract(sin(dot(fragCoord, vec2(12.9898, 78.233))) * 43758.5453) - 0.5) / 255.0;
        encoded += vec3(noise);
    }

    return encoded;
}

