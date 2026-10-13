// SessionDebriefView.swift
// Comprehensive post-session executive scorecard inspired by Speeko and Oratey.
import SwiftUI

public struct SessionDebriefView: View {
    public let debrief: SessionDebrief
    public let onDismiss: () -> Void
    
    public init(debrief: SessionDebrief, onDismiss: @escaping () -> Void) {
        self.debrief = debrief
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        ZStack {
            AppTheme.backgroundGradient.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("EXECUTIVE DEBRIEF")
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
                    
                    // Score Card
                    VStack(spacing: 12) {
                        Text("Executive Readiness Score")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textSecondary)
                        
                        Text("\(debrief.readinessScore)")
                            .font(.system(size: 64, weight: .heavy, design: .rounded))
                            .foregroundStyle(
                                debrief.readinessScore >= 80 ? AppTheme.goldGradient : AppTheme.cyanGradient
                            )
                        
                        Text(debrief.readinessScore >= 80 ? "Boardroom Ready" : "High Potential · Refine Delivery")
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
                    .glassCard(strokeColor: AppTheme.executiveGold.opacity(0.3))
                    
                    // 4-Quadrant Metric Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                        MetricTile(
                            title: "Average Cadence",
                            value: "\(debrief.averageWPM) WPM",
                            subtitle: debrief.cadenceGrade,
                            color: AppTheme.emeraldGreen,
                            icon: "speedometer"
                        )
                        
                        MetricTile(
                            title: "Fillers Detected",
                            value: "\(debrief.fillerCount)",
                            subtitle: debrief.fillerCount == 0 ? "Flawless Eloquence" : "\(debrief.fillerCount) crutches flagged",
                            color: debrief.fillerCount == 0 ? AppTheme.emeraldGreen : AppTheme.coralAlert,
                            icon: "waveform.badge.exclamationmark"
                        )
                        
                        MetricTile(
                            title: "Vocal Range",
                            value: String(format: "%.0f Hz", debrief.pitchRangeHz),
                            subtitle: debrief.pitchRangeHz > 25 ? "Dynamic & Engaging" : "Monotone Risk",
                            color: AppTheme.cyberCyan,
                            icon: "tuningfork"
                        )
                        
                        MetricTile(
                            title: "Framework",
                            value: debrief.frameworkName,
                            subtitle: "\(debrief.durationSeconds)s session",
                            color: AppTheme.electricIndigo,
                            icon: "square.stack.3d.up.fill"
                        )
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
                        Text("Recorded Transcript Sample")
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
