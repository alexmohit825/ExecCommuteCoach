import SwiftUI

@main
struct VocalisApp: App {
    // Initialize telemetry engines
    @StateObject private var acousticEngine = AcousticTelemetryEngineWrapper()
    @StateObject private var speechEngine = SpeechTelemetryEngineWrapper()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(acousticEngine)
                .environmentObject(speechEngine)
        }
    }
}

// Simple wrapper to bridge ObservableObject with the non‑class engine.
final class AcousticTelemetryEngineWrapper: ObservableObject {
    private var engine: AcousticTelemetryEngine?
    @Published var frequency: Float = 0.0
    init() {
        engine = AcousticTelemetryEngine()
        try? engine?.start { [weak self] freq in
            DispatchQueue.main.async { self?.frequency = freq }
        }
    }
    deinit { engine?.stop() }
}

final class SpeechTelemetryEngineWrapper: ObservableObject {
    private var engine = SpeechTelemetryEngine()
    @Published var wpm: Int = 0
    @Published var lastFiller: String = ""
    init() {
        engine.onFillerDetected = { [weak self] filler in
            DispatchQueue.main.async { self?.lastFiller = filler }
        }
        engine.onWPMUpdate = { [weak self] wpm in
            DispatchQueue.main.async { self?.wpm = wpm }
        }
        try? engine.start()
    }
    deinit { engine.stop() }
}
