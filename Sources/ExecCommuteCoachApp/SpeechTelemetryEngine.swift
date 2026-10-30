// SpeechTelemetryEngine.swift
// Continuous speech analysis, filler-word radar, hedging detector, and pause architecture.
// Decoupled from hardware I/O; receives buffers from AudioPipelineEngine with automatic task recycling.
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
    
    private var sessionStartTime: Date?
    private var isSessionActive: Bool = false
    
    // Task Recycling & Continuous Session Continuity
    private var committedTranscript: String = ""
    private var currentSegmentTranscript: String = ""
    private var cycleTimer: Timer?
    private let segmentMaxDurationSeconds: TimeInterval = 48.0
    
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
    var onFillerDetected: ((String, Int, [String: Int]) -> Void)?
    var onHedgingDetected: ((String, Int, [String: Int]) -> Void)?
    var onPauseMetricsUpdate: ((Int, Int) -> Void)?
    
    // Metrics
    private(set) var totalFillersDetected: Int = 0
    private(set) var fillerBreakdown: [String: Int] = [:]
    private(set) var totalHedgingsDetected: Int = 0
    private(set) var hedgingBreakdown: [String: Int] = [:]
    private(set) var strategicPauses: Int = 0
    private(set) var hesitationStalls: Int = 0
    private(set) var currentWPM: Int = 0
    private(set) var fullTranscript: String = ""
    private(set) var totalWordCount: Int = 0
    
    override init() {
        if let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US")) {
            self.recognizer = recognizer
        } else {
            fatalError("Failed to initialize SFSpeechRecognizer for en-US")
        }
        super.init()
        self.recognizer.delegate = self
    }
    
    func start() {
        guard !isSessionActive else { return }
        
        isSessionActive = true
        sessionStartTime = Date()
        committedTranscript = ""
        currentSegmentTranscript = ""
        fullTranscript = ""
        totalWordCount = 0
        totalFillersDetected = 0
        fillerBreakdown.removeAll()
        totalHedgingsDetected = 0
        hedgingBreakdown.removeAll()
        strategicPauses = 0
        hesitationStalls = 0
        
        startRecognitionSegment()
        scheduleSegmentRecycle()
    }
    
    private func startRecognitionSegment() {
        request = SFSpeechAudioBufferRecognitionRequest()
        guard let request = request else { return }
        request.shouldReportPartialResults = true
        
        if recognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        }
        
        task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self, self.isSessionActive else { return }
            
            if let result = result {
                let segmentText = result.bestTranscription.formattedString
                self.currentSegmentTranscript = segmentText
                
                // Assemble seamless full transcript across recycled segments
                let full: String
                if self.committedTranscript.isEmpty {
                    full = segmentText
                } else if segmentText.isEmpty {
                    full = self.committedTranscript
                } else {
                    full = "\(self.committedTranscript) \(segmentText)"
                }
                
                self.fullTranscript = full
                self.onTranscriptUpdate?(full)
                
                self.analyzeTextMetrics(fullText: full, segments: result.bestTranscription.segments)
            }
            
            if let error = error {
                let nsError = error as NSError
                // If timed out or route reset, auto-recover if session is still active
                if self.isSessionActive && nsError.code != 216 {
                    print("Continuous recognition segment recycling on: \(nsError.localizedDescription)")
                    self.recycleCurrentSegment()
                }
            }
        }
    }
    
    private func scheduleSegmentRecycle() {
        cycleTimer?.invalidate()
        cycleTimer = Timer.scheduledTimer(withTimeInterval: segmentMaxDurationSeconds, repeats: true) { [weak self] _ in
            self?.recycleCurrentSegment()
        }
    }
    
    private func recycleCurrentSegment() {
        guard isSessionActive else { return }
        
        // Commit current segment text to historical pool
        if !currentSegmentTranscript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            if committedTranscript.isEmpty {
                committedTranscript = currentSegmentTranscript
            } else {
                committedTranscript += " \(currentSegmentTranscript)"
            }
        }
        currentSegmentTranscript = ""
        
        // Cleanly finish previous task
        request?.endAudio()
        task?.cancel()
        task = nil
        request = nil
        
        // Start fresh segment with zero audio drops
        startRecognitionSegment()
    }
    
    func processBuffer(_ buffer: AVAudioPCMBuffer) {
        guard isSessionActive else { return }
        request?.append(buffer)
    }
    
    private func analyzeTextMetrics(fullText: String, segments: [SFTranscriptionSegment]) {
        let lower = fullText.lowercased()
        let tokens = lower.components(separatedBy: CharacterSet.whitespacesAndNewlines).filter { !$0.isEmpty }
        totalWordCount = tokens.count
        
        // 1. Fillers Analysis
        var newFillerBreakdown: [String: Int] = [:]
        var fillerTotal = 0
        for filler in Self.standardFillers {
            let count = countOccurrences(of: filler, in: lower)
            if count > 0 {
                newFillerBreakdown[filler] = count
                fillerTotal += count
            }
        }
        
        if fillerTotal > totalFillersDetected {
            var latest = "filler"
            for (k, v) in newFillerBreakdown {
                if v > (fillerBreakdown[k] ?? 0) {
                    latest = k
                    break
                }
            }
            totalFillersDetected = fillerTotal
            fillerBreakdown = newFillerBreakdown
            onFillerDetected?(latest, fillerTotal, newFillerBreakdown)
        }
        
        // 2. Hedging & Weak Language Radar
        var newHedgeBreakdown: [String: Int] = [:]
        var hedgeTotal = 0
        for hedge in Self.standardHedgings {
            let count = countOccurrences(of: hedge, in: lower)
            if count > 0 {
                newHedgeBreakdown[hedge] = count
                hedgeTotal += count
            }
        }
        
        if hedgeTotal > totalHedgingsDetected {
            var latestHedge = "qualifier"
            for (k, v) in newHedgeBreakdown {
                if v > (hedgingBreakdown[k] ?? 0) {
                    latestHedge = k
                    break
                }
            }
            totalHedgingsDetected = hedgeTotal
            hedgingBreakdown = newHedgeBreakdown
            onHedgingDetected?(latestHedge, hedgeTotal, newHedgeBreakdown)
        }
        
        // 3. Pause Architecture
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
            if strat != strategicPauses || stall != hesitationStalls {
                strategicPauses = strat
                hesitationStalls = stall
                onPauseMetricsUpdate?(strat, stall)
            }
        }
        
        // 4. Rolling WPM & Cadence Zone
        if let start = sessionStartTime {
            let elapsedMinutes = Date().timeIntervalSince(start) / 60.0
            if elapsedMinutes > 0.05 {
                let wpm = Int(Double(totalWordCount) / elapsedMinutes)
                currentWPM = wpm
                
                let zone: CadenceZone
                if wpm < 125 {
                    zone = .slow
                } else if wpm <= 165 {
                    zone = .optimal
                } else {
                    zone = .rushing
                }
                onWPMUpdate?(wpm, zone)
            }
        }
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
        guard isSessionActive else { return }
        isSessionActive = false
        cycleTimer?.invalidate()
        cycleTimer = nil
        
        request?.endAudio()
        task?.cancel()
        task = nil
        request = nil
    }
}
