package com.kata.videoeditor.nle

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.TextureRegistry

/**
 * Bootstraps the MethodChannel + EventChannel and wires them to the engine.
 *
 * Call [attach] from [MainActivity.configureFlutterEngine] and
 * [detach] from [MainActivity.cleanUpFlutterEngine].
 */
class NleEditorPlugin(
    private val context: Context,
    private val binaryMessenger: BinaryMessenger,
    private val textureRegistry: TextureRegistry
) {
    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null

    private val eventEmitter = NleNativeEventEmitter()

    private val engineManager by lazy {
        NleEngineManager(
            appContext = context,
            eventEmitter = eventEmitter,
            textureRegistry = textureRegistry
        )
    }

    private val commandRouter by lazy {
        NleCommandRouter(engineManager = engineManager, eventEmitter = eventEmitter, context = context)
    }

    fun attach() {
        NleContextHolder.context = context.applicationContext
        methodChannel = MethodChannel(binaryMessenger, NleChannels.METHOD_CHANNEL).also { ch ->
            ch.setMethodCallHandler { call, result ->
                @Suppress("UNCHECKED_CAST")
                val args = (call.arguments as? Map<*, *>)
                    ?.entries
                    ?.associate { it.key.toString() to it.value }
                    ?: emptyMap()

                try {
                    NleNativeBridgeContract.requireCompatibleArgs(call.method, args)
                    val response = commandRouter.route(
                        method = call.method,
                        args   = args
                    )
                    result.success(response)
                } catch (error: Throwable) {
                    result.success(
                        mapOf(
                            "success" to false,
                            "method" to call.method,
                            "error" to mapOf(
                                "code" to NleNativeErrorCode.INVALID_ARGUMENTS,
                                "message" to "The native bridge rejected this command.",
                                "technicalMessage" to error.message
                            )
                        )
                    )
                }
            }
        }

        eventChannel = EventChannel(binaryMessenger, NleChannels.EVENT_CHANNEL).also { ch ->
            ch.setStreamHandler(eventEmitter)
        }
    }

    fun detach() {
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null

        eventChannel?.setStreamHandler(null)
        eventChannel = null
    }
}
