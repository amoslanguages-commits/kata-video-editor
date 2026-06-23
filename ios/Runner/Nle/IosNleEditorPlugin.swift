import Flutter
import UIKit

public class IosNleEditorPlugin: NSObject, FlutterPlugin {
    private let eventEmitter = IosNleEventEmitter()
    private let manager: IosNleEngineManager
    private let router: IosNleCommandRouter

    private let methodChannel: FlutterMethodChannel
    private let eventChannel: FlutterEventChannel

    public init(
        messenger: FlutterBinaryMessenger,
        textureRegistry: FlutterTextureRegistry
    ) {
        self.manager = IosNleEngineManager(
            textureRegistry: textureRegistry,
            eventEmitter: eventEmitter
        )
        self.router = IosNleCommandRouter(manager: manager)

        self.methodChannel = FlutterMethodChannel(
            name: IosNleChannels.methodChannel,
            binaryMessenger: messenger
        )
        self.eventChannel = FlutterEventChannel(
            name: IosNleChannels.eventChannel,
            binaryMessenger: messenger
        )

        super.init()
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        // Registration is performed manually from AppDelegate.swift:
        // nlePlugin = IosNleEditorPlugin(messenger: controller.binaryMessenger, textureRegistry: registrar.textures())
    }

    public func attach() {
        methodChannel.setMethodCallHandler { [weak self] call, result in
            self?.router.handle(call, result: result)
        }
        eventChannel.setStreamHandler(eventEmitter)
    }

    public func detach() {
        methodChannel.setMethodCallHandler(nil)
        eventChannel.setStreamHandler(nil)
        _ = manager.dispose()
    }
}
