// AIAdversaryEngine.swift
// Dynamic adversarial boardroom pushback powered by Gemini 3.8 Flash via Cloudflare Edge Worker.
import Foundation
import AVFoundation

enum BoardroomPersona: String, CaseIterable, Identifiable {
    case investor = "Activist Investor"
    case cfo = "Skeptical CFO"
    case clinical = "Surgical Governance"
    case ceo = "Visionary CEO"
    
    var id: String { rawValue }
    
    var apiCode: String {
        switch self {
        case .investor: return "investor"
        case .cfo: return "cfo"
        case .clinical: return "clinical"
        case .ceo: return "ceo"
        }
    }
    
    var subtitle: String {
        switch self {
        case .investor: return "Probes margins, unit CAC, and ROI."
        case .cfo: return "Scrutinizes downside risk and burn rate."
        case .clinical: return "Demands peer-review & clinical safety."
        case .ceo: return "Tests 10x competitive moat and scale."
        }
    }
}

@MainActor
final class AIAdversaryEngine: NSObject, AVSpeechSynthesizerDelegate {
    static let shared = AIAdversaryEngine()
    
    private var timer: Timer?
    private var isRunning: Bool = false
    private let speechSynthesizer = AVSpeechSynthesizer()
    private let edgeEndpoint = URL(string: "https://vocalis-coach.mohalex.workers.dev/api/spar")!
    
    var activePersona: BoardroomPersona = .cfo
    var onChallengeReceived: ((String) -> Void)?
    
    // Offline / low-latency fallback interruption library
    private static let fallbackPrompts: [BoardroomPersona: [String]] = [
        .investor: [
            "Can you quantify the ROI in under fifteen seconds?",
            "Customer acquisition costs are climbing. How do the unit economics hold up?",
            "What happens to gross margin if enterprise sales cycles double?"
        ],
        .cfo: [
            "Bottom-line it for me: what is the single biggest downside risk?",
            "If this launch slips by sixty days, what is our monthly cash burn?",
            "Have we stress-tested this projection against rising supplier costs?"
        ],
        .clinical: [
            "What verified clinical outcome benchmark protects us during morbidity review?",
            "How does this protocol reduce operative complication risk?",
            "Who assumes direct accountability if this surgical milestone slips?"
        ],
        .ceo: [
            "This sounds tactical. What makes this impossible for competitors to copy?",
            "Cut the preamble: what is the 10x strategic breakthrough here?",
            "How does this move our market valuation forward this fiscal year?"
        ]
    ]
    
    override init() {
        super.init()
        speechSynthesizer.delegate = self
    }
    
    func start(persona: BoardroomPersona = .cfo, onChallenge: @escaping (String) -> Void) {
        stop()
        self.activePersona = persona
        self.onChallengeReceived = onChallenge
        self.isRunning = true
        scheduleNextPushback()
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
        speechSynthesizer.stopSpeaking(at: .immediate)
        isRunning = false
    }
    
    private func scheduleNextPushback() {
        guard isRunning else { return }
        // Interruption fires every 18 to 32 seconds
        let delay = Double.random(in: 18.0...32.0)
        timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, self.isRunning else { return }
                self.triggerContextualPushback()
            }
        }
    }
    
    private func triggerContextualPushback() {
        let transcript = ExecutiveSessionManager.shared.liveTranscript
        
        // If transcript is too short, use smart fallback
        if transcript.components(separatedBy: .whitespacesAndNewlines).filter({ !$0.isEmpty }).count < 8 {
            let fallback = Self.fallbackPrompts[activePersona]?.randomElement() ?? "What is the core conclusion here?"
            deliverChallenge(fallback)
            scheduleNextPushback()
            return
        }
        
        var request = URLRequest(url: edgeEndpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 4.0
        
        let payload: [String: Any] = [
            "transcript": transcript,
            "persona": activePersona.apiCode
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            var challenge = ""
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let text = json["challenge"] as? String,
               !text.isEmpty {
                challenge = text
            }
            
            Task { @MainActor [weak self] in
                guard let self = self, self.isRunning else { return }
                if challenge.isEmpty {
                    challenge = Self.fallbackPrompts[self.activePersona]?.randomElement() ?? "What is the downside risk?"
                }
                self.deliverChallenge(challenge)
                self.scheduleNextPushback()
            }
        }.resume()
    }
    
    private func deliverChallenge(_ text: String) {
        onChallengeReceived?(text)
        speakChallengeInCabin(text)
    }
    
    private func speakChallengeInCabin(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.51
        utterance.pitchMultiplier = 0.98
        utterance.preUtteranceDelay = 0.1
        
        if let voice = AVSpeechSynthesisVoice(identifier: "com.apple.voice.compact.en-US.Samantha") ??
                       AVSpeechSynthesisVoice(language: "en-US") {
            utterance.voice = voice
        }
        
        try? CarAudioDirector.shared.configureSession()
        speechSynthesizer.speak(utterance)
    }
}
