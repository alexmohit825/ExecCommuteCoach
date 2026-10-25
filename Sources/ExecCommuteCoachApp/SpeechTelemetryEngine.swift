// SpeechTelemetryEngine.swift
// Real-time speech analysis, comprehensive filler-word detection, hedging radar, and pause architecture.
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
    
    // Executive Presence 2.0: Hedging & Weak Language Radar
    static let standardHedgings: Set<String> = [
        "i think", "maybe", "hopefully", "in my opinion", "we could try",
        "might be", "just", "sorry to interrupt", "i could be wrong",
        "excuse me if", "somewhat", "presumably", "if that makes sense"
    ]
    
    // Callbacks
    var onTranscriptUpdate: ((String) -> Void)?
    var onWPMUpdate: ((Int, CadenceZone) -> Void)?
    var onFillerDetected: ((String, Int, [String: Int]) -> Void)? // (lastFiller, totalFillers, breakdown)
    var onHedgingDetected: ((String, Int, [String: Int]) -> Void)? // (lastHedge, totalHedging, breakdown)
    var onPauseMetricsUpdate: ((Int, Int) -> Void)? // (strategicPauses, hesitationStalls)
    
    // Metrics
    private(set) var totalFillersDetected: Int = 0
    private(set) var fillerBreakdown: [String: Int] = [:]
    private(set) var totalHedgingsDetected: Int = 0
    private(set) var hedgingBreakdown: [String: Int] = [:]
    private(set) var strategicPauses: Int = 0
    private(set) var hesitationStalls: Int = 0
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
        totalHedgingsDetected = 0
        hedgingBreakdown.removeAll()
        strategicPauses = 0
        hesitationStalls = 0
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
                
                // 1. Fillers Analysis
                var newFillerBreakdown: [String: Int] = [:]
                var fillerTotal = 0
                for filler in Self.standardFillers {
                    let count = self.countOccurrences(of: filler, in: lower)
                    if count > 0 {
                        newFillerBreakdown[filler] = count
                        fillerTotal += count
                    }
                }
                
                if fillerTotal > self.totalFillersDetected {
                    var latest = "filler"
                    for (k, v) in newFillerBreakdown {
                        if v > (self.fillerBreakdown[k] ?? 0) {
                            latest = k
                            break
                        }
                    }
                    self.totalFillersDetected = fillerTotal
                    self.fillerBreakdown = newFillerBreakdown
                    self.onFillerDetected?(latest, fillerTotal, newFillerBreakdown)
                }
                
                // 2. Hedging & Weak Language Radar
                var newHedgeBreakdown: [String: Int] = [:]
                var hedgeTotal = 0
                for hedge in Self.standardHedgings {
                    let count = self.countOccurrences(of: hedge, in: lower)
                    if count > 0 {
                        newHedgeBreakdown[hedge] = count
                        hedgeTotal += count
                    }
                }
                
                if hedgeTotal > self.totalHedgingsDetected {
                    var latestHedge = "qualifier"
                    for (k, v) in newHedgeBreakdown {
                        if v > (self.hedgingBreakdown[k] ?? 0) {
                            latestHedge = k
                            break
                        }
                    }
                    self.totalHedgingsDetected = hedgeTotal
                    self.hedgingBreakdown = newHedgeBreakdown
                    self.onHedgingDetected?(latestHedge, hedgeTotal, newHedgeBreakdown)
                }
                
                // 3. Pause Architecture via Transcription Segments
                let segments = result.bestTranscription.segments
                if segments.count > 1 {
                    var strat = 0
                    var stall = 0
                    for i in 0..<(segments.count - 1) {
                        let currentEnd = segments[i].timestamp + segments[i].duration
                        let nextStart = segments[i + 1].timestamp
                        let gap = nextStart - currentEnd
                        if gap >= 0.75 && gap <= 2.2 {
                            strat += 1
                        } else if gap > 2.5 {
                            stall += 1
                        }
                    }
                    if strat != self.strategicPauses || stall != self.hesitationStalls {
                        self.strategicPauses = strat
                        self.hesitationStalls = stall
                        self.onPauseMetricsUpdate?(strat, stall)
                    }
                }
                
                // 4. Rolling WPM & Cadence Zone
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
