// BreathingPacerView.swift
// Diaphragmatic breathing pacer visualizer with glowing expanding rings (Speak-Up archetype).
import SwiftUI

struct BreathingPacerView: View {
    @ObservedObject var gym: VocalGymEngine
    
    init(gym: VocalGymEngine) {
        self.gym = gym
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Mode selector pill
            Picker("Mode", selection: $gym.breathingMode) {
                ForEach(BreathingMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)
            
            // Dynamic Pacer Circle
            ZStack {
                // Outermost pulsing ring
                Circle()
                    .stroke(AppTheme.cyberCyan.opacity(0.15), lineWidth: 2)
                    .frame(width: 220, height: 220)
                    .scaleEffect(gym.isBreathingActive ? 1.0 + gym.phaseProgress * 0.15 : 1.0)
                
                // Middle glowing aura
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                AppTheme.cyberCyan.opacity(gym.isBreathingActive ? 0.35 : 0.05),
                                AppTheme.electricIndigo.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 10,
                            endRadius: 110
                        )
                    )
                    .frame(width: 180, height: 180)
                    .scaleEffect(gym.isBreathingActive ? 0.7 + gym.phaseProgress * 0.4 : 0.8)
                    .animation(.easeInOut(duration: 0.1), value: gym.phaseProgress)
                
                // Center core
                Circle()
                    .fill(AppTheme.surface)
                    .frame(width: 130, height: 130)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [AppTheme.cyberCyan, AppTheme.executiveGold],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: AppTheme.cyberCyan.opacity(0.3), radius: 15)
                
                // Text overlay
                VStack(spacing: 4) {
                    Text(gym.isBreathingActive ? gym.currentPhase.rawValue : "Ready")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                    
                    if gym.isBreathingActive {
                        Text(String(format: "%.0f%%", gym.phaseProgress * 100))
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(AppTheme.executiveGold)
                    }
                }
            }
            .frame(height: 240)
            
            // Start / Stop Button
            Button(action: {
                if gym.isBreathingActive {
                    gym.stopBreathing()
                } else {
                    gym.startBreathing()
                }
            }) {
                HStack(spacing: 10) {
                    Image(systemName: gym.isBreathingActive ? "stop.fill" : "play.fill")
                    Text(gym.isBreathingActive ? "End Breathing Drill" : "Begin Breathing Pacer")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(gym.isBreathingActive ? AppTheme.coralAlert.opacity(0.25) : AppTheme.cyberCyan.opacity(0.2))
                .foregroundColor(gym.isBreathingActive ? AppTheme.coralAlert : AppTheme.cyberCyan)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(gym.isBreathingActive ? AppTheme.coralAlert : AppTheme.cyberCyan, lineWidth: 1)
                )
            }
            .padding(.horizontal, 24)
        }
        .padding(.vertical, 20)
        .glassCard()
    }
}
