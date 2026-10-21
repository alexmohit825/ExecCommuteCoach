// ExecutiveSessionManager.swift
// Unified orchestrator combining Speeko telemetry, Speak-Up vocal drills, Well-Spoken executive presence, and Oratey frameworks.
import Foundation
import SwiftUI
import Combine

struct SessionDebrief: Identifiable, Codable {
    var id = UUID()
    let timestamp: Date
    let durationSeconds: Int
    let totalWords: Int
    let averageWPM: Int
    let fillerCount: Int
    let fillerBreakdown: [String: Int]
    let readinessScore: Int
    let cadenceGrade: String
    let pitchRangeHz: Float
    let frameworkName: String
    let transcriptSnippet: String
}

@MainActor
final class ExecutiveSessionManager: ObservableObject {
    static let shared = ExecutiveSessionManager()
    
    // MARK: - Engines
    private var acousticEngine: AcousticTelemetryEngine?
    private let speechEngine = SpeechTelemetryEngine()
    private let frictionEngine = FrictionCoachEngine()
    
    // MARK: - Live Telemetry State
    @Published var isSessionActive: Bool = false
    @Published var sessionDuration: Int = 0
    @Published var liveWPM: Int = 0
    @Published var cadenceZone: CadenceZone = .idle
    @Published var fundamentalPitchHz: Float = 0.0
    @Published var audioPower: Float = 0.0
    @Published var spectralBands: [Float] = Array(repeating: 0.08, count: 8)
    @Published var totalFillers: Int = 0
    @Published var fillerBreakdown: [String: Int] = [:]
    @Published var lastFillerDetected: String = ""
    @Published var liveTranscript: String = ""
    @Published var activeFrictionAlert: String = ""
    
    // MARK: - Framework Guidance (Oratey)
    @Published var selectedFramework: ExecutiveFramework = FrameworkCatalog.all[0]
    @Published var currentStepIndex: Int = 0
    @Published var stepRemainingSeconds: Int = 15
    
    // MARK: - Analytics & History (Well-Spoken)
    @Published var currentStreakDays: Int = 3
    @Published var lifetimeWords: Int = 1420
    @Published var lifetimeSessionsCount: Int = 8
    @Published var lastDebrief: SessionDebrief? = nil
    @Published var isDebriefPresented: Bool = false
    
    private var sessionTimer: Timer?
    private var pitchSamples: [Float] = []
    
    init() {
        self.acousticEngine = AcousticTelemetryEngine()
        loadPersistedStats()
        setupEngineCallbacks()
    }
    
    private func setupEngineCallbacks() {
        acousticEngine?.onAcousticUpdate = { [weak self] freq, power, bands in
            Task { @MainActor in
                guard let self = self, self.isSessionActive else { return }
                self.audioPower = power
                self.spectralBands = bands
                if freq > 70.0 && freq < 500.0 {
                    self.fundamentalPitchHz = freq
                    self.pitchSamples.append(freq)
                    if self.pitchSamples.count > 100 {
                        self.pitchSamples.removeFirst()
                    }
                }
            }
        }
        
        speechEngine.onTranscriptUpdate = { [weak self] text in
            Task { @MainActor in
                self?.liveTranscript = text
            }
        }
        
        speechEngine.onWPMUpdate = { [weak self] wpm, zone in
            Task { @MainActor in
                self?.liveWPM = wpm
                self?.cadenceZone = zone
            }
        }
        
        speechEngine.onFillerDetected = { [weak self] filler, total, breakdown in
            Task { @MainActor in
                guard let self = self else { return }
                self.lastFillerDetected = filler
                self.totalFillers = total
                self.fillerBreakdown = breakdown
            }
        }
    }
    
    // MARK: - Session Lifecycle
    func startSession(with framework: ExecutiveFramework? = nil) {
        guard !isSessionActive else { return }
        
        if let fw = framework {
            selectedFramework = fw
        }
        currentStepIndex = 0
        stepRemainingSeconds = selectedFramework.steps.first?.targetSeconds ?? 20
        
        sessionDuration = 0
        liveWPM = 0
        cadenceZone = .idle
        fundamentalPitchHz = 0.0
        audioPower = 0.0
        totalFillers = 0
        fillerBreakdown.removeAll()
        lastFillerDetected = ""
        liveTranscript = ""
        activeFrictionAlert = ""
        pitchSamples.removeAll()
        
        try? acousticEngine?.start()
        try? speechEngine.start()
        
        if selectedFramework.id == "friction" {
            frictionEngine.start { [weak self] prompt in
                Task { @MainActor in
                    self?.activeFrictionAlert = prompt
                }
            }
        }
        
        isSessionActive = true
        
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tickSecond()
            }
        }
    }
    
    private func tickSecond() {
        sessionDuration += 1
        
        if stepRemainingSeconds > 0 {
            stepRemainingSeconds -= 1
        } else {
            // Auto advance or loop step
            if currentStepIndex + 1 < selectedFramework.steps.count {
                currentStepIndex += 1
                stepRemainingSeconds = selectedFramework.steps[currentStepIndex].targetSeconds
            }
        }
    }
    
    func nextFrameworkStep() {
        if currentStepIndex + 1 < selectedFramework.steps.count {
            currentStepIndex += 1
            stepRemainingSeconds = selectedFramework.steps[currentStepIndex].targetSeconds
        }
    }
    
    func endSession() {
        guard isSessionActive else { return }
        
        sessionTimer?.invalidate()
        sessionTimer = nil
        
        acousticEngine?.stop()
        speechEngine.stop()
        frictionEngine.stop()
        isSessionActive = false
        
        // Calculate Debrief
        let score = calculateReadinessScore()
        let minPitch = pitchSamples.min() ?? 120.0
        let maxPitch = pitchSamples.max() ?? 140.0
        let rangeHz = max(0, maxPitch - minPitch)
        
        let words = liveTranscript.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
        
        let grade: String
        switch liveWPM {
        case 130...165: grade = "Executive Optimal"
        case 115..<130: grade = "Measured & Deliberate"
        case 166...185: grade = "Brisk Momentum"
        default: grade = liveWPM < 115 ? "Needs Pacing Lift" : "High-Speed Rush"
        }
        
        let snippet = String(liveTranscript.prefix(180))
        
        let debrief = SessionDebrief(
            timestamp: Date(),
            durationSeconds: max(1, sessionDuration),
            totalWords: words,
            averageWPM: liveWPM,
            fillerCount: totalFillers,
            fillerBreakdown: fillerBreakdown,
            readinessScore: score,
            cadenceGrade: grade,
            pitchRangeHz: rangeHz,
            frameworkName: selectedFramework.name,
            transcriptSnippet: snippet.isEmpty ? "Direct speech exercise recorded." : snippet
        )
        
        lastDebrief = debrief
        isDebriefPresented = true
        
        // Update lifetime stats
        lifetimeWords += words
        lifetimeSessionsCount += 1
        savePersistedStats()
    }
    
    // MARK: - Scoring Algorithm (Speeko & Well-Spoken Synthesis)
    func calculateReadinessScore() -> Int {
        var score = 100
        
        // 1. Cadence Penalty (Target: 130-165 WPM)
        if liveWPM > 0 {
            if liveWPM < 120 {
                let diff = 120 - liveWPM
                score -= min(18, diff / 2)
            } else if liveWPM > 170 {
                let diff = liveWPM - 170
                score -= min(20, diff / 2)
            }
        }
        
        // 2. Filler Density Penalty (3 pts per filler word, capped at 35 pts)
        let fillerPenalty = min(35, totalFillers * 3)
        score -= fillerPenalty
        
        // 3. Monotone / Pitch Variation Bonus / Penalty
        if pitchSamples.count > 10 {
            let minP = pitchSamples.min() ?? 100
            let maxP = pitchSamples.max() ?? 100
            if (maxP - minP) < 25.0 {
                score -= 8 // Monotone deduction
            }
        }
        
        return max(15, min(100, score))
    }
    
    // MARK: - Persistence
    private func loadPersistedStats() {
        let defaults = UserDefaults.standard
        let words = defaults.integer(forKey: "ecc_lifetime_words")
        let sessions = defaults.integer(forKey: "ecc_lifetime_sessions")
        let streak = defaults.integer(forKey: "ecc_current_streak")
        
        if words > 0 { lifetimeWords = words }
        if sessions > 0 { lifetimeSessionsCount = sessions }
        if streak > 0 { currentStreakDays = streak }
    }
    
    private func savePersistedStats() {
        let defaults = UserDefaults.standard
        defaults.set(lifetimeWords, forKey: "ecc_lifetime_words")
        defaults.set(lifetimeSessionsCount, forKey: "ecc_lifetime_sessions")
        defaults.set(currentStreakDays, forKey: "ecc_current_streak")
    }
}
