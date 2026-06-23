import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var nlePlugin: IosNleEditorPlugin?

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
