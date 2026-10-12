// SpeechTelemetryEngine.swift
import Speech
import AVFoundation

/// Captures speech in real‑time, identifies filler words and measures WPM.
final class SpeechTelemetryEngine: NSObject, SFSpeechRecognizerDelegate {
    private let recognizer: SFSpeechRecognizer
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var startTime: Date?
    private var wordCount: Int = 0
    private let fillerSet: Set<String> = ["um", "uh", "like", "you know", "sort of", "essentially"]
    var onFillerDetected: ((String) -> Void)?
    var onWPMUpdate: ((Int) -> Void)?
    
    override init() {
        // On‑device recognizer for offline use.
        if let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US")) {
            recognizer.requiresOnDeviceRecognition = true
            self.recognizer = recognizer
        } else {
            fatalError("Failed to create SFSpeechRecognizer")
        }
        super.init()
        self.recognizer.delegate = self
    }
    
    func start() throws {
        // Request microphone permission if needed.
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        request = SFSpeechAudioBufferRecognitionRequest()
        guard let request = request else { throw NSError(domain: "SpeechTelemetry", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to create request"]) }
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = true
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }
        audioEngine.prepare()
        try audioEngine.start()
        startTime = Date()
        wordCount = 0
        
        task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }
            if let result = result {
                let spoken = result.bestTranscription.formattedString.lowercased()
                let tokens = spoken.split(separator: " ")
                // Update filler detection
                for token in tokens {
                    let word = String(token)
                    if self.fillerSet.contains(word) {
                        self.onFillerDetected?(word)
                    }
                }
                // Update word count and WPM
                self.wordCount = tokens.count
                if let start = self.startTime {
                    let elapsed = Date().timeIntervalSince(start) / 60.0 // minutes
                    if elapsed > 0 {
                        let wpm = Int(Double(self.wordCount) / elapsed)
                        self.onWPMUpdate?(wpm)
                    }
                }
            }
            if let error = error {
                print("Speech telemetry error: \(error)")
            }
        }
    }
    
    func stop() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()
    }
}
