import SwiftUI
import Speech

@main
struct VocalisApp: App {
    // Initialize telemetry engines
    @StateObject private var acousticEngine = AcousticTelemetryEngineWrapper()
    @StateObject private var speechEngine = SpeechTelemetryEngineWrapper()
    @StateObject private var frictionEngine = FrictionCoachEngineWrapper()
    
    init() {
        try? CarAudioDirector.shared.configureSession()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(acousticEngine)
                .environmentObject(speechEngine)
                .environmentObject(frictionEngine)
                .onAppear {
                    // Start dynamic friction mode (default PREP)
                    frictionEngine.start(mode: .prep)
                }
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
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            guard status == .authorized else { return }
            DispatchQueue.main.async { try? self?.engine.start() }
        }
    }
    deinit { engine.stop() }
}
