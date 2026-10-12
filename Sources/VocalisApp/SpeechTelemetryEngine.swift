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
        // On‑device recognition is requested per-request (see start()).
        if let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US")) {
            self.recognizer = recognizer
        } else {
            fatalError("Failed to create SFSpeechRecognizer")
        }
        super.init()
        self.recognizer.delegate = self
    }
    
    func start() throws {
        // Audio session is configured once by CarAudioDirector (playAndRecord).
        request = SFSpeechAudioBufferRecognitionRequest()
        guard let request = request else { throw NSError(domain: "SpeechTelemetry", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to create request"]) }
        request.shouldReportPartialResults = true
        if recognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        }
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        guard recordingFormat.sampleRate > 0, recordingFormat.channelCount > 0 else {
            throw NSError(domain: "SpeechTelemetry", code: -2, userInfo: [NSLocalizedDescriptionKey: "No valid microphone input format"])
        }
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
