// SpeechTelemetryEngine.swift
// Real-time speech analysis, comprehensive filler-word detection, and cadence tracking.
import Speech
import AVFoundation

enum CadenceZone: String {
    case slow = "Slow & Deliberate"
    case optimal = "Optimal Executive"
    case rushing = "Rushing"
    case idle = "Pacing Idle"
}

final class SpeechTelemetryEngine: NSObject, SFSpeechRecognizerDelegate {
    private let recognizer: SFSpeechRecognizer
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    private var sessionStartTime: Date?
    private var wordCount: Int = 0
    private var isRunning: Bool = false
    
    // Comprehensive Speeko / Well-Spoken filler words catalog
    static let standardFillers: Set<String> = [
        "um", "uh", "like", "you know", "actually", "basically",
        "literally", "sort of", "kind of", "i mean", "honestly", "frankly"
    ]
    
    // Callbacks
    var onTranscriptUpdate: ((String) -> Void)?
    var onWPMUpdate: ((Int, CadenceZone) -> Void)?
    var onFillerDetected: ((String, Int, [String: Int]) -> Void)? // (lastFiller, totalFillers, breakdown)
    
    // Metrics
    private(set) var totalFillersDetected: Int = 0
    private(set) var fillerBreakdown: [String: Int] = [:]
    private(set) var currentWPM: Int = 0
    private(set) var fullTranscript: String = ""
    
    override init() {
        if let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US")) {
            self.recognizer = recognizer
        } else {
            fatalError("Failed to initialize SFSpeechRecognizer for en-US")
        }
        super.init()
        self.recognizer.delegate = self
    }
    
    func start() throws {
        guard !isRunning else { return }
        
        request = SFSpeechAudioBufferRecognitionRequest()
        guard let request = request else {
            throw NSError(domain: "SpeechTelemetry", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to create recognition request"])
        }
        request.shouldReportPartialResults = true
        if recognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        }
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        guard recordingFormat.sampleRate > 0, recordingFormat.channelCount > 0 else {
            throw NSError(domain: "SpeechTelemetry", code: -2, userInfo: [NSLocalizedDescriptionKey: "Microphone format is invalid"])
        }
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        sessionStartTime = Date()
        wordCount = 0
        totalFillersDetected = 0
        fillerBreakdown.removeAll()
        fullTranscript = ""
        
        task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                let spoken = result.bestTranscription.formattedString
                self.fullTranscript = spoken
                self.onTranscriptUpdate?(spoken)
                
                let lower = spoken.lowercased()
                let tokens = lower.components(separatedBy: CharacterSet.whitespacesAndNewlines).filter { !$0.isEmpty }
                self.wordCount = tokens.count
                
                // 1. Check for single-word & multi-word fillers
                var newBreakdown: [String: Int] = [:]
                var total = 0
                for filler in Self.standardFillers {
                    let count = self.countOccurrences(of: filler, in: lower)
                    if count > 0 {
                        newBreakdown[filler] = count
                        total += count
                    }
                }
                
                if total > self.totalFillersDetected {
                    // Find what triggered the increment
                    var latest = "filler"
                    for (k, v) in newBreakdown {
                        if v > (self.fillerBreakdown[k] ?? 0) {
                            latest = k
                            break
                        }
                    }
                    self.totalFillersDetected = total
                    self.fillerBreakdown = newBreakdown
                    self.onFillerDetected?(latest, total, newBreakdown)
                }
                
                // 2. Rolling WPM & Cadence Zone
                if let start = self.sessionStartTime {
                    let elapsedMinutes = Date().timeIntervalSince(start) / 60.0
                    if elapsedMinutes > 0.05 { // Wait 3 seconds for stabilization
                        let wpm = Int(Double(self.wordCount) / elapsedMinutes)
                        self.currentWPM = wpm
                        
                        let zone: CadenceZone
                        if wpm < 125 {
                            zone = .slow
                        } else if wpm <= 165 {
                            zone = .optimal
                        } else {
                            zone = .rushing
                        }
                        self.onWPMUpdate?(wpm, zone)
                    }
                }
            }
            
            if let error = error {
                // If cancelled normally on stop, ignore error
                if (error as NSError).code != 216 {
                    print("Speech telemetry observation: \(error.localizedDescription)")
                }
            }
        }
        
        isRunning = true
    }
    
    private func countOccurrences(of target: String, in text: String) -> Int {
        var count = 0
        var searchRange = text.startIndex..<text.endIndex
        while let range = text.range(of: target, options: .caseInsensitive, range: searchRange) {
            // Verify word boundary around matches
            let before = range.lowerBound == text.startIndex || text[text.index(before: range.lowerBound)].isWhitespace
            let after = range.upperBound == text.endIndex || text[range.upperBound].isWhitespace || text[range.upperBound].isPunctuation
            if before && after {
                count += 1
            }
            searchRange = range.upperBound..<text.endIndex
        }
        return count
    }
    
    func stop() {
        guard isRunning else { return }
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()
        task = nil
        request = nil
        isRunning = false
    }
}
