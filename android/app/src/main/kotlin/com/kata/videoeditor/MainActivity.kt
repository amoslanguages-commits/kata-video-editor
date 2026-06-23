package com.kata.videoeditor

import com.kata.videoeditor.nle.NleEditorPlugin
import com.kata.videoeditor.nle.NleVoiceRecorder
import com.kata.videoeditor.nle.NleMediaScanner
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private var nlePlugin: NleEditorPlugin? = null
    private var voiceRecorderChannel: MethodChannel? = null
    private var mediaScannerChannel: MethodChannel? = null
    private var proxyGeneratorChannel: MethodChannel? = null
    private val voiceRecorder = NleVoiceRecorder()
    private val mediaScanner = NleMediaScanner()
    private val proxyGenerator = com.kata.videoeditor.nle.NleProxyGenerator()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        nlePlugin = NleEditorPlugin(
            context         = applicationContext,
            binaryMessenger = flutterEngine.dartExecutor.binaryMessenger,
            textureRegistry = flutterEngine.renderer
        )
        nlePlugin?.attach()

        voiceRecorderChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "nle/voice_recorder").also { ch ->
            ch.setMethodCallHandler { call, result ->
                voiceRecorder.handleMethod(call, result)
            }
        }

        mediaScannerChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "nle/media_scanner").also { ch ->
            ch.setMethodCallHandler { call, result ->
                mediaScanner.handleMethod(call, result)
            }
        }

        proxyGeneratorChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "nle/proxy_generator").also { ch ->
            ch.setMethodCallHandler(proxyGenerator)
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        nlePlugin?.detach()
        nlePlugin = null
        voiceRecorderChannel?.setMethodCallHandler(null)
        voiceRecorderChannel = null
        mediaScannerChannel?.setMethodCallHandler(null)
        mediaScannerChannel = null
        proxyGeneratorChannel?.setMethodCallHandler(null)
        proxyGeneratorChannel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
