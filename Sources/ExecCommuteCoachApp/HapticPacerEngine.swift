// HapticPacerEngine.swift
// CoreHaptics / UIKit tactile pacing engine for 100% eyes-free driving.
// Provides distinct physical feedback for optimal cadence, filler alerts, and strategic pauses.
import UIKit

@MainActor
final class HapticPacerEngine {
    static let shared = HapticPacerEngine()
    
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let rigidImpact = UIImpactFeedbackGenerator(style: .rigid)
    private let notificationGen = UINotificationFeedbackGenerator()
    
    private var lastHapticTime: Date = Date.distantPast
    
    private init() {
        prepare()
    }
    
    func prepare() {
        lightImpact.prepare()
        mediumImpact.prepare()
        heavyImpact.prepare()
        rigidImpact.prepare()
        notificationGen.prepare()
    }
    
    /// Triggered when the speaker enters the "Optimal Executive" 130-165 WPM zone
    func optimalCadenceZoneEntered() {
        guard canTrigger(cooldown: 4.0) else { return }
        mediumImpact.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
            self?.lightImpact.impactOccurred()
        }
    }
    
    /// Triggered when cadence speeds up past 170 WPM (rushing pace)
    func rushingCadenceAlert() {
        guard canTrigger(cooldown: 4.0) else { return }
        notificationGen.notificationOccurred(.warning)
    }
    
    /// Triggered when a filler word or hedging phrase is detected
    func fillerOrHedgeDetected() {
        guard canTrigger(cooldown: 1.5) else { return }
        rigidImpact.impactOccurred()
    }
    
    /// Triggered when a strategic pause (0.8s - 2.0s) is recognized
    func strategicPauseRewarded() {
        guard canTrigger(cooldown: 3.0) else { return }
        notificationGen.notificationOccurred(.success)
    }
    
    /// Triggered when an AI pushback begins
    func aiPushbackIncoming() {
        heavyImpact.impactOccurred()
    }
    
    private func canTrigger(cooldown: TimeInterval) -> Bool {
        let now = Date()
        if now.timeIntervalSince(lastHapticTime) >= cooldown {
            lastHapticTime = now
            return true
        }
        return false
    }
}
