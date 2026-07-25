import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var nlePlugin: IosNleEditorPlugin?
  private let voiceRecorder = IosNleVoiceRecorder()
  private let mediaScanner = IosNleMediaScanner()
  private let proxyGenerator = IosNleProxyGenerator()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)

    if let controller = window?.rootViewController as? FlutterViewController,
       let registrar = self.registrar(forPlugin: "IosNleEditorPlugin") {
      nlePlugin = IosNleEditorPlugin(
        messenger: controller.binaryMessenger,
        textureRegistry: registrar.textures()
      )
      nlePlugin?.attach()

      // Auxiliary channels matching the Android MainActivity registrations.
      let voiceChannel = FlutterMethodChannel(
        name: "nle/voice_recorder",
        binaryMessenger: controller.binaryMessenger
      )
      voiceChannel.setMethodCallHandler { [weak self] call, result in
        self?.voiceRecorder.handle(call, result: result)
      }

      let mediaChannel = FlutterMethodChannel(
        name: "nle/media_scanner",
        binaryMessenger: controller.binaryMessenger
      )
      mediaChannel.setMethodCallHandler { [weak self] call, result in
        self?.mediaScanner.handle(call, result: result)
      }

      let proxyChannel = FlutterMethodChannel(
        name: "nle/proxy_generator",
        binaryMessenger: controller.binaryMessenger
      )
      proxyChannel.setMethodCallHandler { [weak self] call, result in
        self?.proxyGenerator.handle(call, result: result)
      }
    }

    return result
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  override func applicationWillTerminate(_ application: UIApplication) {
    nlePlugin?.detach()
    nlePlugin = nil
    super.applicationWillTerminate(application)
  }
}
