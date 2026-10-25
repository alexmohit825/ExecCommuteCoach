// VocalGymEngine.swift
// Physical vocal gym inspired by Speak-Up: breathing pacer, articulation drills, and resonance warmups.
import Foundation
import SwiftUI

enum BreathingMode: String, CaseIterable, Identifiable {
    case box = "Box (4-4-4-4)"
    case calm = "Executive Reset (4-7-8)"
    case commute = "Drive Pulse (3-3-6)"
    
    var id: String { rawValue }
    
    var intervals: (inhale: Double, hold1: Double, exhale: Double, hold2: Double) {
        switch self {
        case .box: return (4.0, 4.0, 4.0, 4.0)
        case .calm: return (4.0, 7.0, 8.0, 0.0)
        case .commute: return (3.0, 3.0, 6.0, 0.0)
        }
    }
}

enum BreathingPhase: String {
    case inhale = "Inhale Deeply"
    case hold = "Hold Presence"
    case exhale = "Release & Ground"
    case rest = "Stillness"
}

struct ArticulationDrill: Identifiable {
    let id = UUID()
    let title: String
    let phoneticTarget: String
    let prompt: String
    let difficulty: String
    let executiveBenefit: String
}

final class VocalGymEngine: ObservableObject {
    // Breathing state
    @Published var breathingMode: BreathingMode = .box
    @Published var currentPhase: BreathingPhase = .inhale
    @Published var phaseProgress: CGFloat = 0.0
    @Published var isBreathingActive: Bool = false
    
    private var breathTimer: Timer?
    private var phaseElapsed: Double = 0.0
    
    // Articulation Drills Catalog
    @Published var drills: [ArticulationDrill] = [
        ArticulationDrill(
            title: "Plosive Authority",
            phoneticTarget: "/p/ & /k/ Plosives",
            prompt: "Proper copper coffee pots produce powerful boardroom persuasion.",
            difficulty: "Medium",
            executiveBenefit: "Eliminates mumbling; adds crisp punch to opening executive statements."
        ),
        ArticulationDrill(
            title: "Lingual Precision",
            phoneticTarget: "/l/ & /r/ Transitions",
            prompt: "Red leather, yellow leather, rare leverage, real leadership.",
            difficulty: "Hard",
            executiveBenefit: "Improves rapid syllable clarity under high-pressure Q&A."
        ),
        ArticulationDrill(
            title: "Sibilant Control",
            phoneticTarget: "/s/ & /st/ Clusters",
            prompt: "Specific statistics systematically substantiate strategic solutions.",
            difficulty: "Expert",
            executiveBenefit: "Tames microphone hiss and sharpens technical presentations."
        ),
        ArticulationDrill(
            title: "Vocal Resonance Ladder",
            phoneticTarget: "Diaphragmatic Chest Hum",
            prompt: "Hum smoothly at low chest pitch: Mmmmm-One... Mmmmm-Two... Mmmmm-Three.",
            difficulty: "Foundational",
            executiveBenefit: "Lowers throat tension; anchors vocal pitch into authoritative chest register."
        )
    ]
    
    func startBreathing() {
        stopBreathing()
        isBreathingActive = true
        currentPhase = .inhale
        phaseElapsed = 0.0
        phaseProgress = 0.0
        
        breathTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.tickBreathing()
        }
    }
    
    func stopBreathing() {
        breathTimer?.invalidate()
        breathTimer = nil
        isBreathingActive = false
        phaseProgress = 0.0
    }
    
    private func tickBreathing() {
        phaseElapsed += 0.05
        let ints = breathingMode.intervals
        
        switch currentPhase {
        case .inhale:
            phaseProgress = CGFloat(min(phaseElapsed / ints.inhale, 1.0))
            if phaseElapsed >= ints.inhale {
                phaseElapsed = 0.0
                currentPhase = ints.hold1 > 0 ? .hold : .exhale
            }
        case .hold:
            phaseProgress = CGFloat(min(phaseElapsed / ints.hold1, 1.0))
            if phaseElapsed >= ints.hold1 {
                phaseElapsed = 0.0
                currentPhase = .exhale
            }
        case .exhale:
            phaseProgress = CGFloat(1.0 - min(phaseElapsed / ints.exhale, 1.0))
            if phaseElapsed >= ints.exhale {
                phaseElapsed = 0.0
                currentPhase = ints.hold2 > 0 ? .rest : .inhale
            }
        case .rest:
            phaseProgress = CGFloat(min(phaseElapsed / ints.hold2, 1.0))
            if phaseElapsed >= ints.hold2 {
                phaseElapsed = 0.0
                currentPhase = .inhale
            }
        }
    }
    
    deinit {
        stopBreathing()
    }
}
