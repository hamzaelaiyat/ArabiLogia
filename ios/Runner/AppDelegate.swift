import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var secureChannel: FlutterMethodChannel?
  private var isObserving = false

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let engine = engineBridge.engine
    secureChannel = FlutterMethodChannel(name: "com.arabilogia.app/secure", binaryMessenger: engine.binaryMessenger)
    secureChannel?.setMethodCallHandler { [weak self] (call, result) in
      switch call.method {
      case "enableSecure":
        self?.startCaptureObserving()
        result(true)
      case "disableSecure":
        self?.stopCaptureObserving()
        result(true)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func startCaptureObserving() {
    guard !isObserving else { return }
    isObserving = true
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(screenCaptureStateChanged),
      name: UIScreen.capturedDidChangeNotification,
      object: nil
    )
    let isCaptured = UIScreen.main.isCaptured
    secureChannel?.invokeMethod("onCaptureStateChanged", arguments: ["isCaptured": isCaptured])
  }

  private func stopCaptureObserving() {
    guard isObserving else { return }
    isObserving = false
    NotificationCenter.default.removeObserver(
      self,
      name: UIScreen.capturedDidChangeNotification,
      object: nil
    )
    secureChannel?.invokeMethod("onCaptureStateChanged", arguments: ["isCaptured": false])
  }

  @objc private func screenCaptureStateChanged() {
    let isCaptured = UIScreen.main.isCaptured
    secureChannel?.invokeMethod("onCaptureStateChanged", arguments: ["isCaptured": isCaptured])
  }
}
