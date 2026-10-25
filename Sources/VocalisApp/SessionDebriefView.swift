// SessionDebriefView.swift
// Comprehensive post-session executive scorecard inspired by Speeko and Oratey, with Gemini 3.8 AI debriefing.
import SwiftUI

struct SessionDebriefView: View {
    let debrief: SessionDebrief
    let onDismiss: () -> Void
    
    init(debrief: SessionDebrief, onDismiss: @escaping () -> Void) {
        self.debrief = debrief
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("EXECUTIVE DEBRIEF 2.0")
                                .font(.system(size: 11, weight: .bold))
                                .tracking(2)
                                .foregroundColor(AppTheme.executiveGold)
                            Text("Session Telemetry Scorecard")
                                .font(.title2).bold()
                                .foregroundColor(AppTheme.textPrimary)
                        }
                        Spacer()
                        Button(action: onDismiss) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                    .padding(.top, 16)
                    
                    // Executive Score Card
                    VStack(spacing: 12) {
                        Text("Executive Readiness Score")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textSecondary)
                        
                        Text("\(debrief.readinessScore)")
                            .font(.system(size: 64, weight: .heavy, design: .rounded))
                            .foregroundStyle(
                                debrief.readinessScore >= 80 ? AppTheme.goldGradient : AppTheme.cyanGradient
                            )
                        
                        Text(debrief.readinessScore >= 80 ? "Boardroom Ready · High Authority" : "Refine Pacing & Eliminate Hedging")
                            .font(.caption).bold()
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(
                                (debrief.readinessScore >= 80 ? AppTheme.executiveGold : AppTheme.cyberCyan)
                                    .opacity(0.18)
                            )
                            .cornerRadius(12)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .glassCard(strokeColor: AppTheme.executiveGold.opacity(0.35))
                    
                    // AI Executive Briefing Card (Gemini 3.8 Flash)
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(AppTheme.executiveGold)
                            Text("AI Executive Intelligence Verdict")
                                .font(.subheadline).bold()
                                .foregroundColor(AppTheme.executiveGold)
                        }
                        
                        VStack(alignment: .leading, spacing: 10) {
                            DebriefBullet(icon: "shield.checkmark.fill", color: AppTheme.emeraldGreen, title: "Verdict", text: debrief.aiVerdict)
                            DebriefBullet(icon: "anchor.fill", color: AppTheme.cyberCyan, title: "Strongest Anchor", text: debrief.aiAnchor)
                            DebriefBullet(icon: "exclamationmark.triangle.fill", color: AppTheme.coralAlert, title: "Fatal Flaw to Scrub", text: debrief.aiFlaw)
                        }
                    }
                    .padding(18)
                    .glassCard(strokeColor: AppTheme.executiveGold.opacity(0.25))
                    
                    // 6-Quadrant Metric Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                        MetricTile(
                            title: "Average Cadence",
                            value: "\(debrief.averageWPM) WPM",
                            subtitle: debrief.cadenceGrade,
                            color: AppTheme.emeraldGreen,
                            icon: "speedometer"
                        )
                        
                        MetricTile(
                            title: "Fillers Flagged",
                            value: "\(debrief.fillerCount)",
                            subtitle: debrief.fillerCount == 0 ? "Zero Verbal Crutches" : "\(debrief.fillerCount) fillers detected",
                            color: debrief.fillerCount == 0 ? AppTheme.emeraldGreen : AppTheme.coralAlert,
                            icon: "waveform.badge.exclamationmark"
                        )
                        
                        MetricTile(
                            title: "Hedging Phrases",
                            value: "\(debrief.hedgingCount)",
                            subtitle: debrief.hedgingCount == 0 ? "Decisive & Confident" : "\(debrief.hedgingCount) qualifiers found",
                            color: debrief.hedgingCount == 0 ? AppTheme.emeraldGreen : AppTheme.coralAlert,
                            icon: "shield.slash.fill"
                        )
                        
                        MetricTile(
                            title: "Strategic Pauses",
                            value: "\(debrief.strategicPauses)",
                            subtitle: "\(debrief.hesitationStalls) stalls recorded",
                            color: AppTheme.cyberCyan,
                            icon: "pause.circle.fill"
                        )
                        
                        MetricTile(
                            title: "Vocal Modulation",
                            value: debrief.modulationGrade,
                            subtitle: String(format: "±%.1f Hz dynamic range", debrief.pitchStdDev),
                            color: AppTheme.electricIndigo,
                            icon: "tuningfork"
                        )
                        
                        MetricTile(
                            title: "Framework",
                            value: debrief.frameworkName,
                            subtitle: "\(debrief.durationSeconds)s duration",
                            color: AppTheme.executiveGold,
                            icon: "square.stack.3d.up.fill"
                        )
                    }
                    
                    // Hedging Language Breakdown Chips
                    if !debrief.hedgingBreakdown.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Hedging & Weak Language Scrub")
                                .font(.headline)
                                .foregroundColor(AppTheme.textPrimary)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(debrief.hedgingBreakdown.sorted(by: { $0.value > $1.value }), id: \.key) { key, count in
                                        HStack(spacing: 6) {
                                            Text("\"\(key)\"")
                                                .font(.subheadline).bold()
                                                .foregroundColor(AppTheme.textPrimary)
                                            Text("×\(count)")
                                                .font(.caption).bold()
                                                .foregroundColor(AppTheme.coralAlert)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(AppTheme.surface)
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(AppTheme.coralAlert.opacity(0.3), lineWidth: 1)
                                        )
                                    }
                                }
                            }
                        }
                        .padding(16)
                        .glassCard()
                    }
                    
                    // Filler Words Breakdown Chips
                    if !debrief.fillerBreakdown.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Filler Word Analysis")
                                .font(.headline)
                                .foregroundColor(AppTheme.textPrimary)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(debrief.fillerBreakdown.sorted(by: { $0.value > $1.value }), id: \.key) { key, count in
                                        HStack(spacing: 6) {
                                            Text(key.capitalized)
                                                .font(.subheadline).bold()
                                                .foregroundColor(AppTheme.textPrimary)
                                            Text("×\(count)")
                                                .font(.caption).bold()
                                                .foregroundColor(AppTheme.coralAlert)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(AppTheme.surface)
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(AppTheme.coralAlert.opacity(0.3), lineWidth: 1)
                                        )
                                    }
                                }
                            }
                        }
                        .padding(16)
                        .glassCard()
                    }
                    
                    // Transcript Snippet
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recorded Speech Snippet")
                            .font(.headline)
                            .foregroundColor(AppTheme.textPrimary)
                        Text("\"\(debrief.transcriptSnippet)\"")
                            .font(.callout)
                            .foregroundColor(AppTheme.textSecondary)
                            .italic()
                            .lineSpacing(4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .glassCard()
                    
                    // Action Button
                    Button(action: onDismiss) {
                        Text("Complete & Return to Cockpit")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(AppTheme.goldGradient)
                            .foregroundColor(Color.black)
                            .cornerRadius(16)
                            .shadow(color: AppTheme.executiveGold.opacity(0.35), radius: 10)
                    }
                    .padding(.bottom, 32)
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

private struct DebriefBullet: View {
    let icon: String
    let color: Color
    let title: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 14))
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption).bold()
                    .foregroundColor(color)
                Text(text)
                    .font(.footnote)
                    .foregroundColor(AppTheme.textPrimary)
                    .lineSpacing(2)
            }
        }
    }
}

private struct MetricTile: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 16))
                Spacer()
            }
            Text(title)
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
            Text(value)
                .font(.title3).bold()
                .foregroundColor(AppTheme.textPrimary)
            Text(subtitle)
                .font(.system(size: 11))
                .foregroundColor(color)
                .lineLimit(1)
        }
        .padding(14)
        .glassCard()
    }
}
