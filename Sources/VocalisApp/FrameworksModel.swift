// FrameworksModel.swift
// Executive communication frameworks inspired by Oratey (PREP, STAR, Pyramid Principle, Adversarial Scrutiny).
import Foundation

public struct FrameworkStep: Identifiable, Hashable {
    public let id = UUID()
    public let title: String
    public let guidance: String
    public let promptCue: String
    public let targetSeconds: Int
}

public struct ExecutiveFramework: Identifiable, Hashable {
    public let id: String
    public let name: String
    public let acronym: String
    public let category: String
    public let overview: String
    public let steps: [FrameworkStep]
    
    public static func == (lhs: ExecutiveFramework, rhs: ExecutiveFramework) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

public enum FrameworkCatalog {
    public static let all: [ExecutiveFramework] = [
        ExecutiveFramework(
            id: "prep",
            name: "PREP Method",
            acronym: "PREP",
            category: "Executive Brevity",
            overview: "Deliver razor-sharp, conclusive business updates in under 60 seconds without rambling.",
            steps: [
                FrameworkStep(title: "Point", guidance: "State your direct recommendation or core conclusion immediately.", promptCue: "Bottom line: We must approve Project Alpha today.", targetSeconds: 15),
                FrameworkStep(title: "Reason", guidance: "Provide the primary strategic rationale driving your point.", promptCue: "Because our competitor is launching in Q3 and we hold a 2-month head start.", targetSeconds: 20),
                FrameworkStep(title: "Example", guidance: "Cite concrete data, pilot metrics, or proof points.", promptCue: "Our Seattle pilot converted at 34%, delivering $180K in initial ARR.", targetSeconds: 25),
                FrameworkStep(title: "Point Restated", guidance: "Reiterate your point with a clear executive call-to-action.", promptCue: "Therefore, signing the vendor contract by Friday protects our advantage.", targetSeconds: 15)
            ]
        ),
        ExecutiveFramework(
            id: "star",
            name: "STAR Framework",
            acronym: "STAR",
            category: "Interview & Boardroom",
            overview: "Structure high-stakes case responses and executive achievements with verifiable impact.",
            steps: [
                FrameworkStep(title: "Situation", guidance: "Set the context in 1-2 sentences. Avoid backstory bloat.", promptCue: "During the 2024 cloud migration, our payment gateway suffered sudden latency spikes.", targetSeconds: 20),
                FrameworkStep(title: "Task", guidance: "Clarify your direct responsibility and ownership.", promptCue: "I was tasked with identifying root-cause and restoring sub-50ms latency within 48 hours.", targetSeconds: 15),
                FrameworkStep(title: "Action", guidance: "Explain the strategic moves YOU executed, not just the team.", promptCue: "I mobilized an isolate team, rewrote edge caching rules, and bypassed legacy VPC hops.", targetSeconds: 40),
                FrameworkStep(title: "Result", guidance: "Highlight quantified business metrics, revenue saved, and learnings.", promptCue: "Latency dropped to 18ms, preventing an estimated $1.2M in cart abandonment.", targetSeconds: 25)
            ]
        ),
        ExecutiveFramework(
            id: "pyramid",
            name: "Pyramid Principle",
            acronym: "Minto",
            category: "Strategic Briefings",
            overview: "McKinsey standard: lead with the core answer first, then logical grouping, then supporting data.",
            steps: [
                FrameworkStep(title: "Governing Thought", guidance: "The single overarching answer or executive decision requested.", promptCue: "We should acquire LogiFlow for $4.5M to eliminate our supply-chain blindspot.", targetSeconds: 20),
                FrameworkStep(title: "Supporting Pillars", guidance: "Group 2-3 mutually exclusive, collectively exhaustive (MECE) reasons.", promptCue: "First, it cuts fulfillment time by 40%. Second, it adds 12 enterprise accounts.", targetSeconds: 30),
                FrameworkStep(title: "Evidence & Horizon", guidance: "Detail financial validation, risk mitigation, and execution horizon.", promptCue: "Cash payback occurs in 14 months, and tech integration requires zero replatforming.", targetSeconds: 35)
            ]
        ),
        ExecutiveFramework(
            id: "friction",
            name: "Boardroom Pushback",
            acronym: "Defense",
            category: "Adversarial Stress Test",
            overview: "Simulates sudden interruptions and aggressive stakeholder scrutiny during commute practice.",
            steps: [
                FrameworkStep(title: "Opening Thesis", guidance: "Begin pitching your proposal clearly.", promptCue: "Deliver your core project update until the board interrupts.", targetSeconds: 25),
                FrameworkStep(title: "Sustain Under Fire", guidance: "Maintain calm vocal resonance and avoid fillers when interrupted.", promptCue: "Acknowledge the pushback calmly, state the exact risk mitigant, and pivot back.", targetSeconds: 35)
            ]
        )
    ]
}
