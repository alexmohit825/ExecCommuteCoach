// FrictionCoachEngine.swift
// Simulates adversarial boardroom pushback during executive speech sessions.
import Foundation

final class FrictionCoachEngine {
    private var timer: Timer?
    private var interruptionCallback: ((String) -> Void)?
    private var isRunning: Bool = false
    
    public static let standardInterruptions: [String] = [
        "What’s the downside risk?",
        "Can you quantify the ROI in under 15 seconds?",
        "Bottom-line it for me.",
        "How does this align with our Q4 capital allocation?",
        "What’s the critical-path timeline?",
        "Who owns the failure mode if this slips?",
        "Have we stress-tested this assumption against inflation?",
        "Cut the preamble—what’s the actual headcount requirement?"
    ]
    
    func start(onInterrupt: @escaping (String) -> Void) {
        stop()
        self.interruptionCallback = onInterrupt
        self.isRunning = true
        scheduleNextInterrupt()
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }
    
    private func scheduleNextInterrupt() {
        guard isRunning else { return }
        // Random interruption between 12 and 28 seconds
        let delay = Double.random(in: 12.0...28.0)
        timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            guard let self = self, self.isRunning else { return }
            let phrase = Self.standardInterruptions.randomElement() ?? "Can you quantify the ROI?"
            self.interruptionCallback?(phrase)
            self.scheduleNextInterrupt()
        }
    }
    
    deinit {
        stop()
    }
}
