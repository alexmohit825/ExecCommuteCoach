// FrameworksModel.swift
// Executive communication frameworks inspired by Oratey (PREP, STAR, Pyramid Principle, Capital Defense, Surgical Governance, Crisis).
import Foundation

struct FrameworkStep: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let guidance: String
    let promptCue: String
    let targetSeconds: Int
}

struct ExecutiveFramework: Identifiable, Hashable {
    let id: String
    let name: String
    let acronym: String
    let category: String
    let overview: String
    let steps: [FrameworkStep]
    
    static func == (lhs: ExecutiveFramework, rhs: ExecutiveFramework) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

enum FrameworkCatalog {
    static let all: [ExecutiveFramework] = [
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
            id: "capital",
            name: "Capital Allocation Defense",
            acronym: "CAPITAL",
            category: "Boardroom Finance",
            overview: "Defend high-stakes $5M-$20M capital expenditures against severe scrutiny from skeptical CFOs.",
            steps: [
                FrameworkStep(title: "The Ask & Payback", guidance: "State requested capital and expected payback timeline.", promptCue: "We are requesting $12M to expand our robotics facility with a 19-month cash breakeven.", targetSeconds: 20),
                FrameworkStep(title: "Unit Economics", guidance: "Demonstrate margin expansion and operating leverage.", promptCue: "Unit manufacturing cost drops 42%, lifting gross margins to 68%.", targetSeconds: 25),
                FrameworkStep(title: "Downside Stress Test", guidance: "Show what happens under high-inflation or recession scenarios.", promptCue: "Even if volume drops 30%, our debt service coverage ratio remains above 2.4x.", targetSeconds: 30),
                FrameworkStep(title: "Execution Gating", guidance: "Propose milestone-based capital tranches to mitigate risk.", promptCue: "Tranche 1 releases $4M upon completion of structural clean-room certification.", targetSeconds: 20)
            ]
        ),
        ExecutiveFramework(
            id: "clinical",
            name: "Surgical Governance Defense",
            acronym: "M&M",
            category: "Clinical Excellence",
            overview: "Lead peer review and morbidity reviews with complete objectivity, clinical mastery, and zero defensiveness.",
            steps: [
                FrameworkStep(title: "Case Protocol", guidance: "Directly state the clinical condition and surgical indication.", promptCue: "The patient presented with unstable cervical myelopathy requiring urgent C3-C6 decompression.", targetSeconds: 20),
                FrameworkStep(title: "Evidence Benchmark", guidance: "Cite verified peer-reviewed literature and standard of care.", promptCue: "The intervention followed AO Spine Class I surgical guidelines with intraoperative neuro-monitoring.", targetSeconds: 25),
                FrameworkStep(title: "Root Cause & Mitigation", guidance: "Acknowledge anatomic anomalies or hardware variance with zero excuses.", promptCue: "V3 vertebral artery tortuosity was identified on pre-op CTA and fully mobilized prior to screw placement.", targetSeconds: 30),
                FrameworkStep(title: "Systemic Safeguard", guidance: "Present the enduring quality improvement protocol implemented.", promptCue: "We integrated mandatory dual-surgeon scrub verification for all complex spinal reconstructions.", targetSeconds: 20)
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
            name: "AI Boardroom Pushback",
            acronym: "Sparring",
            category: "Adversarial Stress Test",
            overview: "Live Gemini 3.8 Flash AI actively challenges your pitch over the car speakers in real time.",
            steps: [
                FrameworkStep(title: "Opening Thesis", guidance: "Begin pitching your proposal clearly.", promptCue: "Deliver your core project update until the AI board member interrupts.", targetSeconds: 25),
                FrameworkStep(title: "Sustain Under Fire", guidance: "Maintain calm vocal resonance and avoid fillers when interrupted.", promptCue: "Acknowledge the pushback calmly, state the exact risk mitigant, and pivot back.", targetSeconds: 35)
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
            id: "crisis",
            name: "Crisis & Hostile Media",
            acronym: "CRISIS",
            category: "High-Stakes PR",
            overview: "Address severe operational incidents, compliance issues, or hostile stakeholder inquiries with commanding presence.",
            steps: [
                FrameworkStep(title: "Immediate Accountability", guidance: "Acknowledge the situation directly without deflection.", promptCue: "At 06:00 today, our regional data center suffered a power drop affecting 14% of transactions.", targetSeconds: 15),
                FrameworkStep(title: "Action Deployed", guidance: "State concrete containment steps already active.", promptCue: "All traffic was rerouted to our Oregon facility, and core data integrity remains 100% verified.", targetSeconds: 25),
                FrameworkStep(title: "Restitution & Audit", guidance: "Outline proactive customer compensation and independent audit.", promptCue: "We commissioned an external engineering audit and will issue full credits to affected enterprise accounts.", targetSeconds: 20)
            ]
        )
    ]
}
