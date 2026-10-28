import AVFoundation
import Flutter
import Speech
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var speechBridge: SpeechBridge?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "SpeechBridge") {
      speechBridge = SpeechBridge(messenger: registrar.messenger())
    }
  }
}

/// Speech recognition for the speaking trial (card LL-71).
///
/// A small bridge over `SFSpeechRecognizer` instead of a plugin, because the
/// trial needs `contextualStrings` (the words the recogniser should expect)
/// and the alternative readings, which the plugins do not hand over.
///
/// Methods (channel `eu.btimpl.languagelearner/speech`):
/// - `authorize` -> "granted" | "denied" | "unavailable"
/// - `listen` {locale, hints, maxSeconds} -> {alternatives: [String], onDevice: Bool}
///   Listens until the speaker pauses, `stop` is called or `maxSeconds` pass.
///   While listening it calls `partial` (String) on the Dart side.
/// - `stop` ends the listening early; the result of `listen` still arrives.
final class SpeechBridge {
  private let channel: FlutterMethodChannel
  private let audioEngine = AVAudioEngine()
  private var request: SFSpeechAudioBufferRecognitionRequest?
  private var task: SFSpeechRecognitionTask?
  private var pending: FlutterResult?
  private var alternatives: [String] = []
  private var onDevice = false
  private var maxTimer: Timer?
  private var pauseTimer: Timer?
  private var graceTimer: Timer?

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(
      name: "eu.btimpl.languagelearner/speech",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result: result)
    }
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "authorize":
      authorize(result)
    case "listen":
      let args = call.arguments as? [String: Any] ?? [:]
      listen(
        locale: args["locale"] as? String ?? "en-GB",
        hints: args["hints"] as? [String] ?? [],
        maxSeconds: args["maxSeconds"] as? Double ?? 8,
        result: result
      )
    case "stop":
      stopAudio()
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func authorize(_ result: @escaping FlutterResult) {
    SFSpeechRecognizer.requestAuthorization { status in
      DispatchQueue.main.async {
        switch status {
        case .authorized:
          AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async { result(granted ? "granted" : "denied") }
          }
        case .denied, .restricted:
          result("denied")
        default:
          result("unavailable")
        }
      }
    }
  }

  private func listen(locale: String, hints: [String], maxSeconds: Double, result: @escaping FlutterResult) {
    guard pending == nil else {
      result(FlutterError(code: "busy", message: "Already listening", details: nil))
      return
    }
    guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: locale)),
      recognizer.isAvailable
    else {
      result(FlutterError(code: "unavailable", message: "Recognizer not available", details: nil))
      return
    }
    do {
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
      try session.setActive(true, options: .notifyOthersOnDeactivation)

      let request = SFSpeechAudioBufferRecognitionRequest()
      request.shouldReportPartialResults = true
      request.contextualStrings = hints
      self.request = request
      alternatives = []
      onDevice = recognizer.supportsOnDeviceRecognition
      pending = result

      let input = audioEngine.inputNode
      let format = input.outputFormat(forBus: 0)
      input.removeTap(onBus: 0)
      input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
        request.append(buffer)
      }
      audioEngine.prepare()
      try audioEngine.start()

      task = recognizer.recognitionTask(with: request) { [weak self] recognition, error in
        DispatchQueue.main.async {
          guard let self = self, self.pending != nil else { return }
          if let recognition = recognition {
            self.alternatives = recognition.transcriptions.map { $0.formattedString }
            self.channel.invokeMethod("partial", arguments: recognition.bestTranscription.formattedString)
            self.restartPauseTimer()
            if recognition.isFinal {
              self.complete()
              return
            }
          }
          if error != nil {
            self.complete()
          }
        }
      }
      maxTimer = Timer.scheduledTimer(withTimeInterval: maxSeconds, repeats: false) { [weak self] _ in
        self?.stopAudio()
      }
    } catch {
      cleanup()
      let reply = pending ?? result
      pending = nil
      reply(FlutterError(code: "failed", message: error.localizedDescription, details: nil))
    }
  }

  /// A pause after the first words ends the listening.
  private func restartPauseTimer() {
    pauseTimer?.invalidate()
    pauseTimer = Timer.scheduledTimer(withTimeInterval: 1.2, repeats: false) { [weak self] _ in
      self?.stopAudio()
    }
  }

  /// Stops the microphone; the recogniser then delivers the final result.
  private func stopAudio() {
    guard pending != nil else { return }
    maxTimer?.invalidate()
    pauseTimer?.invalidate()
    if audioEngine.isRunning {
      audioEngine.stop()
      audioEngine.inputNode.removeTap(onBus: 0)
    }
    request?.endAudio()
    // If the final result does not come, finish with what we have.
    graceTimer?.invalidate()
    graceTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { [weak self] _ in
      self?.complete()
    }
  }

  private func complete() {
    guard let reply = pending else { return }
    pending = nil
    let heard = alternatives
    let local = onDevice
    cleanup()
    reply(["alternatives": heard, "onDevice": local])
  }

  private func cleanup() {
    maxTimer?.invalidate()
    pauseTimer?.invalidate()
    graceTimer?.invalidate()
    if audioEngine.isRunning {
      audioEngine.stop()
      audioEngine.inputNode.removeTap(onBus: 0)
    }
    task?.cancel()
    task = nil
    request = nil
    // Back to the playback category of the read-aloud, so it sounds again.
    let session = AVAudioSession.sharedInstance()
    try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
    try? session.setActive(true, options: .notifyOthersOnDeactivation)
  }
}
