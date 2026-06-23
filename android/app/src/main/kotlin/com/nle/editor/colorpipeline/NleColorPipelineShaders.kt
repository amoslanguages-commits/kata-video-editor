package com.nle.editor.colorpipeline

object NleColorPipelineShaders {

    const val fullscreenVertex = """
        attribute vec2 aPosition;
        attribute vec2 aTexCoord;

        varying vec2 vTexCoord;

        void main() {
            vTexCoord = aTexCoord;
            gl_Position = vec4(aPosition, 0.0, 1.0);
        }
    """

    fun passthroughFragment(colorManagementGlsl: String): String {
        return """
            precision highp float;

            varying vec2 vTexCoord;

            uniform sampler2D uTexture;

            $colorManagementGlsl

            void main() {
                vec4 src = texture2D(uTexture, vTexCoord);
                gl_FragColor = src;
            }
        """
    }

    fun inputToSceneLinearFragment(colorManagementGlsl: String): String {
        return """
            precision highp float;

            varying vec2 vTexCoord;

            uniform sampler2D uTexture;

            $colorManagementGlsl

            void main() {
                vec4 src = texture2D(uTexture, vTexCoord);

                vec3 working = nleColorManageToWorking(src.rgb);

                gl_FragColor = vec4(working, src.a);
            }
        """
    }

    fun outputDisplayTransformFragment(colorManagementGlsl: String): String {
        return """
            precision highp float;

            varying vec2 vTexCoord;

            uniform sampler2D uTexture;

            $colorManagementGlsl

            void main() {
                vec4 src = texture2D(uTexture, vTexCoord);

                vec3 outRgb = nleColorManageToOutput(src.rgb, gl_FragCoord.xy);

                gl_FragColor = vec4(outRgb, src.a);
            }
        """
    }

    const val debugBandingRampFragment = """
        precision highp float;

        varying vec2 vTexCoord;

        void main() {
            float ramp = vTexCoord.x;
            gl_FragColor = vec4(vec3(ramp), 1.0);
        }
    """
}
