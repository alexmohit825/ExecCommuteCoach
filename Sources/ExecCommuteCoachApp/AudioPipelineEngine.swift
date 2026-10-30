// AudioPipelineEngine.swift
// Unified single-engine Audio I/O Controller for ExecCommuteCoach.
// Eliminates dual-AVAudioEngine hardware conflicts, manages CarPlay route changes,
// and enforces acoustic muting during AI sparring speech playback.
import AVFoundation

final class AudioPipelineEngine {
    static let shared = AudioPipelineEngine()
    
    private let audioEngine = AVAudioEngine()
    private let bus: AVAudioNodeBus = 0
    private(set) var isRunning: Bool = false
    
    // Acoustic Echo Cancellation: Drops microphone buffers during AI voice playback
    var isMutedForPlayback: Bool = false
    
    // Callbacks
    var onAcousticBuffer: ((AVAudioPCMBuffer, Double) -> Void)?
    var onSpeechBuffer: ((AVAudioPCMBuffer) -> Void)?
    
    private var routeObserver: NSObjectProtocol?
    private var configChangeObserver: NSObjectProtocol?
    
    private init() {
        setupNotifications()
    }
    
    deinit {
        if let obs = routeObserver { NotificationCenter.default.removeObserver(obs) }
        if let obs = configChangeObserver { NotificationCenter.default.removeObserver(obs) }
    }
    
    private func setupNotifications() {
        routeObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleAudioRouteChange(notification)
        }
        
        configChangeObserver = NotificationCenter.default.addObserver(
            forName: .AVAudioEngineConfigurationChange,
            object: audioEngine,
            queue: .main
        ) { [weak self] _ in
            self?.handleEngineConfigurationChange()
        }
    }
    
    func start() throws {
        guard !isRunning else { return }
        
        // 1. Ensure AVAudioSession is active for Bluetooth / CarPlay duplex audio
        try CarAudioDirector.shared.configureSession()
        
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.inputFormat(forBus: bus)
        
        guard inputFormat.sampleRate > 0, inputFormat.channelCount > 0 else {
            throw NSError(
                domain: "AudioPipelineEngine",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Hardware microphone input format invalid or unavailable"]
            )
        }
        
        // Remove existing tap defensively
        inputNode.removeTap(onBus: bus)
        
        let sampleRate = inputFormat.sampleRate
        inputNode.installTap(onBus: bus, bufferSize: 1024, format: inputFormat) { [weak self] buffer, _ in
            guard let self = self, self.isRunning else { return }
            
            // 1. Always pass to acoustic analyzer for live ambient visualization & pitch
            self.onAcousticBuffer?(buffer, sampleRate)
            
            // 2. Pass to speech recognizer ONLY if not muted by AI speech output (AEC)
            if !self.isMutedForPlayback {
                self.onSpeechBuffer?(buffer)
            }
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        isRunning = true
    }
    
    func stop() {
        guard isRunning else { return }
        isRunning = false
        audioEngine.inputNode.removeTap(onBus: bus)
        audioEngine.stop()
    }
    
    private func handleAudioRouteChange(_ notification: Notification) {
        guard isRunning else { return }
        // If route changed (e.g., connected to CarPlay or Bluetooth), reconfigure cleanly
        restartPipeline()
    }
    
    private func handleEngineConfigurationChange() {
        guard isRunning else { return }
        restartPipeline()
    }
    
    private func restartPipeline() {
        stop()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            guard let self = self else { return }
            do {
                try self.start()
            } catch {
                print("Audio pipeline restart notice: \(error.localizedDescription)")
            }
        }
    }
}
