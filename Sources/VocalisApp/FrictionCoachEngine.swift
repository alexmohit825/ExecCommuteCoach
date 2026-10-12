// FrictionCoachEngine.swift
import Foundation
import AVFoundation

/// Generates adversarial “push‑back” prompts during a live speech session.
/// The engine schedules a random interruption within a configurable window.
final class FrictionCoachEngine {
    enum Mode {
        case prep   // 60‑second executive defense
        case star   // STAR behavioral response
        case impromptu // Table‑topics style
    }
    
    private var timer: Timer?
    private var interruptionCallback: ((String) -> Void)?
    private var mode: Mode = .prep
    private let interruptionPhrases: [String] = [
        "What’s the downside risk?",
        "Can you quantify the ROI?",
        "Bottom‑line it for me.",
        "How does this align with strategy?",
        "What’s the timeline?",
        "Who owns the deliverables?"
    ]
    
    /// Starts a coaching session for the chosen mode.
    func start(mode: Mode, onInterrupt: @escaping (String) -> Void) {
        self.mode = mode
        self.interruptionCallback = onInterrupt
        scheduleNextInterrupt()
    }
    
    /// Cancels any pending interruption.
    func stop() {
        timer?.invalidate()
        timer = nil
    }
    
    private func scheduleNextInterrupt() {
        // Random delay between 10‑30 seconds depending on mode.
        let minDelay: TimeInterval = 10
        let maxDelay: TimeInterval = (mode == .impromptu) ? 20 : 30
        let delay = TimeInterval.random(in: minDelay...maxDelay)
        timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            let phrase = self.interruptionPhrases.randomElement() ?? "Can you elaborate?"
            self.interruptionCallback?(phrase)
            // Schedule next if still running.
            self.scheduleNextInterrupt()
        }
    }
}
