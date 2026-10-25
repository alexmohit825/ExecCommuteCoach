// ContentView.swift
// Main executive speech cockpit rolling Speeko, Speak-Up, Well-Spoken, and Oratey into a unified interface.
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var session: ExecutiveSessionManager
    @StateObject private var vocalGym = VocalGymEngine()
    @State private var selectedTab: Int = 0
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient.ignoresSafeArea()
            
            TabView(selection: $selectedTab) {
                CockpitView(gym: vocalGym)
                    .tabItem {
                        Label("Cockpit", systemImage: "waveform.circle.fill")
                    }
                    .tag(0)
                
                VocalGymView(gym: vocalGym)
                    .tabItem {
                        Label("Vocal Gym", systemImage: "lungs.fill")
                    }
                    .tag(1)
                
                FrameworksView()
                    .tabItem {
                        Label("Frameworks", systemImage: "square.stack.3d.up.fill")
                    }
                    .tag(2)
                
                AnalyticsView()
                    .tabItem {
                        Label("Analytics", systemImage: "chart.bar.xaxis")
                    }
                    .tag(3)
            }
            .tint(AppTheme.executiveGold)
        }
        .sheet(isPresented: $session.isDebriefPresented) {
            if let debrief = session.lastDebrief {
                SessionDebriefView(debrief: debrief) {
                    session.isDebriefPresented = false
                }
            }
        }
    }
}

// MARK: - Tab 1: Cockpit View
struct CockpitView: View {
    @EnvironmentObject var session: ExecutiveSessionManager
    @ObservedObject var gym: VocalGymEngine
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Top Executive Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("EXEC COMMUTE COACH 2.0")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(2)
                            .foregroundColor(AppTheme.executiveGold)
                        Text("Executive Cockpit")
                            .font(.title2).bold()
                            .foregroundColor(AppTheme.textPrimary)
                    }
                    Spacer()
                    // Streak Pill
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(AppTheme.executiveGold)
                        Text("\(session.currentStreakDays) Days")
                            .font(.subheadline).bold()
                            .foregroundColor(AppTheme.textPrimary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .glassCard(strokeColor: AppTheme.executiveGold.opacity(0.3), cornerRadius: 14)
                }
                .padding(.top, 12)
                
                // Live Waveform Visualizer
                LiveWaveformView(
                    spectralBands: session.spectralBands,
                    audioPower: session.audioPower,
                    isActive: session.isSessionActive
                )
                
                // Primary Telemetry Row 1 (Cadence & Fillers)
                HStack(spacing: 12) {
                    // Cadence Card
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: "speedometer")
                                .foregroundColor(AppTheme.emeraldGreen)
                            Spacer()
                            Text(session.cadenceZone.rawValue)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(AppTheme.emeraldGreen)
                                .lineLimit(1)
                        }
                        Text("\(session.liveWPM)")
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundColor(AppTheme.textPrimary)
                        Text("Words / Min (130-165)")
                            .font(.system(size: 10))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .padding(14)
                    .glassCard()
                    
                    // Filler Sentinel
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: "exclamationmark.bubble.fill")
                                .foregroundColor(AppTheme.coralAlert)
                            Spacer()
                            if !session.lastFillerDetected.isEmpty {
                                Text(session.lastFillerDetected.uppercased())
                                    .font(.system(size: 9, weight: .heavy))
                                    .foregroundColor(AppTheme.coralAlert)
                            }
                        }
                        Text("\(session.totalFillers)")
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundColor(session.totalFillers > 0 ? AppTheme.coralAlert : AppTheme.textPrimary)
                        Text("Fillers Flagged")
                            .font(.system(size: 10))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .padding(14)
                    .glassCard()
                }
                
                // Telemetry Row 2 (Hedging Radar & Pause Architecture)
                HStack(spacing: 12) {
                    // Hedging Radar Card
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: "shield.slash.fill")
                                .foregroundColor(session.totalHedgings > 0 ? AppTheme.coralAlert : AppTheme.cyberCyan)
                            Spacer()
                            if !session.lastHedgingDetected.isEmpty {
                                Text("\"\(session.lastHedgingDetected)\"")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(AppTheme.coralAlert)
                                    .lineLimit(1)
                            }
                        }
                        Text("\(session.totalHedgings)")
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundColor(session.totalHedgings > 0 ? AppTheme.coralAlert : AppTheme.textPrimary)
                        Text("Hedging Phrases")
                            .font(.system(size: 10))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .padding(14)
                    .glassCard()
                    
                    // Strategic Pauses Card
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: "pause.circle.fill")
                                .foregroundColor(AppTheme.cyberCyan)
                            Spacer()
                            Text(session.modulationGrade)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(AppTheme.cyberCyan)
                                .lineLimit(1)
                        }
                        Text("\(session.strategicPauses)")
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundColor(AppTheme.textPrimary)
                        Text("Strategic Pauses (\(session.hesitationStalls) stalls)")
                            .font(.system(size: 10))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .padding(14)
                    .glassCard()
                }
                
                // Boardroom Adversary Persona Selector
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(AppTheme.executiveGold)
                        Text("AI Boardroom Sparring Persona")
                            .font(.subheadline).bold()
                            .foregroundColor(AppTheme.textPrimary)
                        Spacer()
                    }
                    
                    HStack(spacing: 8) {
                        ForEach(BoardroomPersona.allCases) { persona in
                            let isSelected = session.activePersona == persona
                            Button(action: {
                                session.activePersona = persona
                            }) {
                                Text(persona.rawValue)
                                    .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity)
                                    .background(isSelected ? AppTheme.executiveGold.opacity(0.25) : AppTheme.surfaceLight)
                                    .foregroundColor(isSelected ? AppTheme.executiveGold : AppTheme.textSecondary)
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(isSelected ? AppTheme.executiveGold.opacity(0.4) : Color.clear, lineWidth: 1)
                                    )
                            }
                        }
                    }
                    
                    Text(session.activePersona.subtitle)
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                        .padding(.top, 2)
                }
                .padding(16)
                .glassCard(strokeColor: AppTheme.executiveGold.opacity(0.2))
                
                // Framework Guided Teleprompter (Oratey)
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(AppTheme.executiveGold)
                        Text(session.selectedFramework.name)
                            .font(.headline)
                            .foregroundColor(AppTheme.textPrimary)
                        Spacer()
                        if session.isSessionActive {
                            Text("\(session.stepRemainingSeconds)s")
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(AppTheme.executiveGold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(AppTheme.executiveGold.opacity(0.15))
                                .cornerRadius(8)
                        }
                    }
                    
                    if let step = session.selectedFramework.steps[safe: session.currentStepIndex] {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("STEP \(session.currentStepIndex + 1): \(step.title.uppercased())")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(AppTheme.cyberCyan)
                                Spacer()
                            }
                            Text(step.guidance)
                                .font(.subheadline)
                                .foregroundColor(AppTheme.textSecondary)
                            Text("\"\(step.promptCue)\"")
                                .font(.callout).italic()
                                .foregroundColor(AppTheme.textPrimary)
                                .padding(.top, 4)
                        }
                    }
                    
                    // Dynamic AI Adversary Pushback Banner
                    if !session.activeFrictionAlert.isEmpty {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "bolt.fill")
                                .foregroundColor(AppTheme.coralAlert)
                                .padding(.top, 2)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(session.activePersona.rawValue.uppercased()) PUSHBACK:")
                                    .font(.system(size: 10, weight: .heavy))
                                    .foregroundColor(AppTheme.coralAlert)
                                Text("\"\(session.activeFrictionAlert)\"")
                                    .font(.footnote).bold()
                                    .foregroundColor(Color.white)
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppTheme.coralAlert.opacity(0.2))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppTheme.coralAlert.opacity(0.4), lineWidth: 1)
                        )
                    }
                    
                    if session.isSessionActive && session.selectedFramework.steps.count > 1 {
                        Button(action: { session.nextFrameworkStep() }) {
                            HStack {
                                Text("Advance Step")
                                    .font(.caption).bold()
                                Image(systemName: "arrow.right")
                                    .font(.caption)
                            }
                            .foregroundColor(AppTheme.cyberCyan)
                        }
                        .padding(.top, 2)
                    }
                }
                .padding(16)
                .glassCard(strokeColor: AppTheme.executiveGold.opacity(0.2))
                
                // Commute Session Primary Button
                Button(action: {
                    if session.isSessionActive {
                        session.endSession()
                    } else {
                        session.startSession()
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: session.isSessionActive ? "stop.circle.fill" : "mic.fill")
                            .font(.system(size: 20))
                        Text(session.isSessionActive ? "Stop & Review Scorecard (\(session.sessionDuration)s)" : "Begin Commute Coaching")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        session.isSessionActive ?
                        LinearGradient(colors: [AppTheme.coralAlert, Color(red: 0.8, green: 0.2, blue: 0.2)], startPoint: .leading, endPoint: .trailing) :
                        AppTheme.goldGradient
                    )
                    .foregroundColor(session.isSessionActive ? Color.white : Color.black)
                    .cornerRadius(18)
                    .shadow(color: (session.isSessionActive ? AppTheme.coralAlert : AppTheme.executiveGold).opacity(0.4), radius: 12)
                }
                .padding(.top, 4)
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Tab 2: Vocal Gym View (Speak-Up)
struct VocalGymView: View {
    @ObservedObject var gym: VocalGymEngine
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("VOCAL GYM & DRILLS")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(2)
                        .foregroundColor(AppTheme.cyberCyan)
                    Text("Physical Articulation & Breath")
                        .font(.title2).bold()
                        .foregroundColor(AppTheme.textPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 12)
                
                // Diaphragmatic Breathing Pacer
                BreathingPacerView(gym: gym)
                
                // Articulation Diction Drills
                VStack(alignment: .leading, spacing: 14) {
                    Text("Articulation & Consonant Punches")
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)
                    
                    ForEach(gym.drills) { drill in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(drill.title)
                                    .font(.subheadline).bold()
                                    .foregroundColor(AppTheme.textPrimary)
                                Spacer()
                                Text(drill.difficulty)
                                    .font(.system(size: 10, weight: .bold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(AppTheme.electricIndigo.opacity(0.2))
                                    .foregroundColor(AppTheme.electricIndigo)
                                    .cornerRadius(6)
                            }
                            Text(drill.phoneticTarget)
                                .font(.caption).bold()
                                .foregroundColor(AppTheme.cyberCyan)
                            Text("\"\(drill.prompt)\"")
                                .font(.callout).italic()
                                .foregroundColor(AppTheme.textPrimary)
                                .lineSpacing(3)
                            Text(drill.executiveBenefit)
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        .padding(14)
                        .glassCard()
                    }
                }
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Tab 3: Frameworks View (Oratey)
struct FrameworksView: View {
    @EnvironmentObject var session: ExecutiveSessionManager
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("EXECUTIVE FRAMEWORKS 2.0")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(2)
                        .foregroundColor(AppTheme.electricIndigo)
                    Text("Structured Communication")
                        .font(.title2).bold()
                        .foregroundColor(AppTheme.textPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 12)
                
                ForEach(FrameworkCatalog.all) { framework in
                    let isCurrent = session.selectedFramework.id == framework.id
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(framework.name)
                                .font(.headline).bold()
                                .foregroundColor(AppTheme.textPrimary)
                            Spacer()
                            Text(framework.category)
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(AppTheme.executiveGold.opacity(0.2))
                                .foregroundColor(AppTheme.executiveGold)
                                .cornerRadius(6)
                        }
                        
                        Text(framework.overview)
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textSecondary)
                        
                        // Steps pills
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(framework.steps) { step in
                                    Text(step.title)
                                        .font(.system(size: 11, weight: .medium))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(AppTheme.surfaceLight)
                                        .foregroundColor(AppTheme.textPrimary)
                                        .cornerRadius(6)
                                }
                            }
                        }
                        
                        Button(action: {
                            session.selectedFramework = framework
                        }) {
                            Text(isCurrent ? "Active in Cockpit" : "Select for Practice")
                                .font(.caption).bold()
                                .frame(maxWidth: .infinity)
                                .frame(height: 38)
                                .background(isCurrent ? AppTheme.cyberCyan.opacity(0.25) : AppTheme.surfaceLight)
                                .foregroundColor(isCurrent ? AppTheme.cyberCyan : AppTheme.textPrimary)
                                .cornerRadius(10)
                        }
                    }
                    .padding(16)
                    .glassCard(strokeColor: isCurrent ? AppTheme.cyberCyan : Color.white.opacity(0.1))
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
    }
}

// MARK: - Tab 4: Analytics View (Well-Spoken)
struct AnalyticsView: View {
    @EnvironmentObject var session: ExecutiveSessionManager
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("EXECUTIVE MASTERY")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(2)
                        .foregroundColor(AppTheme.emeraldGreen)
                    Text("Presence & Cadence Trends")
                        .font(.title2).bold()
                        .foregroundColor(AppTheme.textPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 12)
                
                // Executive Readiness Score Card
                VStack(spacing: 10) {
                    Text("Executive Readiness Score")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                    
                    Text("\(session.calculateReadinessScore())")
                        .font(.system(size: 56, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppTheme.goldGradient)
                    
                    Text("Synthesized across cadence, filler cleanliness, hedging radar, and pause timing")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .glassCard(strokeColor: AppTheme.executiveGold.opacity(0.25))
                
                // Lifetime Numbers
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Words Coached")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                        Text("\(session.lifetimeWords)")
                            .font(.title2).bold()
                            .foregroundColor(AppTheme.textPrimary)
                    }
                    .padding(14)
                    .glassCard()
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Commute Sessions")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                        Text("\(session.lifetimeSessionsCount)")
                            .font(.title2).bold()
                            .foregroundColor(AppTheme.cyberCyan)
                    }
                    .padding(14)
                    .glassCard()
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Practice Streak")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                        Text("\(session.currentStreakDays) Days")
                            .font(.title2).bold()
                            .foregroundColor(AppTheme.executiveGold)
                    }
                    .padding(14)
                    .glassCard()
                }
                
                // Last Session Summary Tile
                if let debrief = session.lastDebrief {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Latest Session Debrief")
                                .font(.headline)
                                .foregroundColor(AppTheme.textPrimary)
                            Spacer()
                            Button("View Card") {
                                session.isDebriefPresented = true
                            }
                            .font(.caption).bold()
                            .foregroundColor(AppTheme.cyberCyan)
                        }
                        
                        Text("\(debrief.frameworkName) · \(debrief.averageWPM) WPM · \(debrief.fillerCount) Fillers · \(debrief.hedgingCount) Hedges")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textSecondary)
                        
                        if !debrief.aiVerdict.isEmpty {
                            Text("AI Verdict: \(debrief.aiVerdict)")
                                .font(.caption).italic()
                                .foregroundColor(AppTheme.executiveGold)
                                .lineLimit(2)
                        }
                    }
                    .padding(16)
                    .glassCard()
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
    }
}

// Collection safe subscript helper
extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
