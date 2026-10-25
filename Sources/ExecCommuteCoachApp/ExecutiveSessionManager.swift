// ExecutiveSessionManager.swift
// Unified orchestrator combining Speeko telemetry, Speak-Up vocal drills, Well-Spoken presence, and Oratey frameworks.
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
    let hedgingCount: Int
    let hedgingBreakdown: [String: Int]
    let strategicPauses: Int
    let hesitationStalls: Int
    let readinessScore: Int
    let cadenceGrade: String
    let pitchRangeHz: Float
    let pitchStdDev: Float
    let modulationGrade: String
    let frameworkName: String
    let transcriptSnippet: String
    var aiVerdict: String
    var aiAnchor: String
    var aiFlaw: String
}

@MainActor
final class ExecutiveSessionManager: ObservableObject {
    static let shared = ExecutiveSessionManager()
    
    // MARK: - Engines
    private var acousticEngine: AcousticTelemetryEngine?
    private let speechEngine = SpeechTelemetryEngine()
    private let aiAdversaryEngine = AIAdversaryEngine.shared
    
    // MARK: - Live Telemetry State
    @Published var isSessionActive: Bool = false
    @Published var sessionDuration: Int = 0
    @Published var liveWPM: Int = 0
    @Published var cadenceZone: CadenceZone = .idle
    @Published var fundamentalPitchHz: Float = 0.0
    @Published var audioPower: Float = 0.0
    @Published var spectralBands: [Float] = Array(repeating: 0.08, count: 8)
    
    // Filler Radar
    @Published var totalFillers: Int = 0
    @Published var fillerBreakdown: [String: Int] = [:]
    @Published var lastFillerDetected: String = ""
    
    // Hedging & Weak Language Radar (Telemetry 2.0)
    @Published var totalHedgings: Int = 0
    @Published var hedgingBreakdown: [String: Int] = [:]
    @Published var lastHedgingDetected: String = ""
    
    // Pause Architecture
    @Published var strategicPauses: Int = 0
    @Published var hesitationStalls: Int = 0
    
    // Vocal Modulation & Monotony
    @Published var pitchStdDev: Float = 0.0
    @Published var modulationGrade: String = "Calibrating"
    
    // Live Transcript & Pushback
    @Published var liveTranscript: String = ""
    @Published var activeFrictionAlert: String = ""
    
    // MARK: - Framework & Persona Guidance
    @Published var selectedFramework: ExecutiveFramework = FrameworkCatalog.all[0]
    @Published var activePersona: BoardroomPersona = .cfo
    @Published var currentStepIndex: Int = 0
    @Published var stepRemainingSeconds: Int = 15
    
    // MARK: - Analytics & History
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
                    if self.pitchSamples.count > 120 {
                        self.pitchSamples.removeFirst()
                    }
                }
            }
        }
        
        acousticEngine?.onModulationUpdate = { [weak self] stdDev, grade in
            Task { @MainActor in
                guard let self = self, self.isSessionActive else { return }
                self.pitchStdDev = stdDev
                self.modulationGrade = grade
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
        
        speechEngine.onHedgingDetected = { [weak self] hedge, total, breakdown in
            Task { @MainActor in
                guard let self = self else { return }
                self.lastHedgingDetected = hedge
                self.totalHedgings = total
                self.hedgingBreakdown = breakdown
            }
        }
        
        speechEngine.onPauseMetricsUpdate = { [weak self] strat, stall in
            Task { @MainActor in
                guard let self = self else { return }
                self.strategicPauses = strat
                self.hesitationStalls = stall
            }
        }
    }
    
    // MARK: - Session Lifecycle
    func startSession(with framework: ExecutiveFramework? = nil, persona: BoardroomPersona? = nil) {
        guard !isSessionActive else { return }
        
        if let fw = framework {
            selectedFramework = fw
        }
        if let pr = persona {
            activePersona = pr
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
        totalHedgings = 0
        hedgingBreakdown.removeAll()
        lastHedgingDetected = ""
        strategicPauses = 0
        hesitationStalls = 0
        pitchStdDev = 0.0
        modulationGrade = "Calibrating"
        liveTranscript = ""
        activeFrictionAlert = ""
        pitchSamples.removeAll()
        
        try? acousticEngine?.start()
        try? speechEngine.start()
        
        // Start AI Boardroom Adversary Pushback
        if selectedFramework.id == "friction" || selectedFramework.id == "capital" {
            aiAdversaryEngine.start(persona: activePersona) { [weak self] challenge in
                Task { @MainActor in
                    self?.activeFrictionAlert = challenge
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
        aiAdversaryEngine.stop()
        isSessionActive = false
        
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
        
        let snippet = String(liveTranscript.prefix(200))
        
        let debrief = SessionDebrief(
            timestamp: Date(),
            durationSeconds: max(1, sessionDuration),
            totalWords: words,
            averageWPM: liveWPM,
            fillerCount: totalFillers,
            fillerBreakdown: fillerBreakdown,
            hedgingCount: totalHedgings,
            hedgingBreakdown: hedgingBreakdown,
            strategicPauses: strategicPauses,
            hesitationStalls: hesitationStalls,
            readinessScore: score,
            cadenceGrade: grade,
            pitchRangeHz: rangeHz,
            pitchStdDev: pitchStdDev,
            modulationGrade: modulationGrade,
            frameworkName: selectedFramework.name,
            transcriptSnippet: snippet.isEmpty ? "Direct speech rehearsal recorded." : snippet,
            aiVerdict: "Calculating AI executive assessment...",
            aiAnchor: "Opening thesis delivered with executive clarity.",
            aiFlaw: "Transition into financial justification could be tightened."
        )
        
        lastDebrief = debrief
        isDebriefPresented = true
        
        // Fetch AI Debrief asynchronously from Edge Worker
        fetchAIDebrief(transcript: liveTranscript, wpm: liveWPM, fillers: totalFillers, hedgings: totalHedgings)
        
        lifetimeWords += words
        lifetimeSessionsCount += 1
        savePersistedStats()
    }
    
    private func fetchAIDebrief(transcript: String, wpm: Int, fillers: Int, hedgings: Int) {
        guard !transcript.isEmpty else { return }
        guard let url = URL(string: "https://execcommute-coach.mohalex.workers.dev/api/debrief") else { return }
        
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 5.0
        
        let body: [String: Any] = [
            "transcript": transcript,
            "wpm": wpm,
            "fillers": fillers,
            "hedgings": hedgings
        ]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: req) { [weak self] data, _, _ in
            guard let self = self, let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
            
            let verdict = json["verdict"] as? String ?? ""
            let anchor = json["anchor"] as? String ?? ""
            let flaw = json["flaw"] as? String ?? ""
            
            DispatchQueue.main.async {
                if var cur = self.lastDebrief {
                    if !verdict.isEmpty { cur.aiVerdict = verdict }
                    if !anchor.isEmpty { cur.aiAnchor = anchor }
                    if !flaw.isEmpty { cur.aiFlaw = flaw }
                    self.lastDebrief = cur
                }
            }
        }.resume()
    }
    
    // MARK: - Comprehensive Presence Scoring (Speeko + Well-Spoken + Oratey)
    func calculateReadinessScore() -> Int {
        var score = 100
        
        // 1. Cadence Penalty (Target: 130-165 WPM)
        if liveWPM > 0 {
            if liveWPM < 120 {
                let diff = 120 - liveWPM
                score -= min(16, diff / 2)
            } else if liveWPM > 170 {
                let diff = liveWPM - 170
                score -= min(18, diff / 2)
            }
        }
        
        // 2. Filler Penalty (-3 per filler, max -30)
        let fillerPenalty = min(30, totalFillers * 3)
        score -= fillerPenalty
        
        // 3. Hedging & Weak Language Penalty (-4 per hedge, max -25)
        let hedgePenalty = min(25, totalHedgings * 4)
        score -= hedgePenalty
        
        // 4. Strategic Pause Bonus (+2 per pause, max +10)
        let pauseBonus = min(10, strategicPauses * 2)
        score += pauseBonus
        
        // 5. Hesitation Stall Penalty (-3 per stall, max -15)
        let stallPenalty = min(15, hesitationStalls * 3)
        score -= stallPenalty
        
        // 6. Vocal Modulation Bonus / Penalty
        if modulationGrade == "Dynamic & Commanding" {
            score += 5
        } else if modulationGrade == "Monotone / Droning" {
            score -= 6
        }
        
        return max(20, min(99, score))
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
