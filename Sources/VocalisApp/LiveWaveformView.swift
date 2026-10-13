// LiveWaveformView.swift
// Live animated multi-band fluid waveform visualizer (Well-Spoken executive aesthetic).
import SwiftUI

public struct LiveWaveformView: View {
    public let spectralBands: [Float]
    public let audioPower: Float
    public let isActive: Bool
    
    @State private var phase: CGFloat = 0
    
    public init(spectralBands: [Float], audioPower: Float, isActive: Bool) {
        self.spectralBands = spectralBands
        self.audioPower = audioPower
        self.isActive = isActive
    }
    
    public var body: some View {
        ZStack {
            // Ambient glow backing
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    RadialGradient(
                        colors: [
                            AppTheme.cyberCyan.opacity(isActive ? Double(audioPower * 0.35) : 0.05),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 160
                    )
                )
                .blur(radius: 20)
            
            HStack(spacing: 6) {
                ForEach(0..<16, id: \.self) { index in
                    let bandVal = bandHeight(for: index)
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    barTopColor(for: index),
                                    barBottomColor(for: index)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 6, height: max(6, bandVal))
                        .animation(.interpolatingSpring(stiffness: 260, damping: 18), value: bandVal)
                }
            }
            .frame(height: 90)
        }
        .frame(height: 120)
        .padding(.horizontal, 16)
        .glassCard(strokeColor: isActive ? AppTheme.cyberCyan.opacity(0.4) : Color.white.opacity(0.1))
    }
    
    private func bandHeight(for index: Int) -> CGFloat {
        guard isActive else {
            // Idle gentle harmonic wave
            let wave = sin(Double(index) * 0.45) * 6 + 12
            return CGFloat(wave)
        }
        
        // Map 16 visual bars symmetrically to 8 FFT spectral bands
        let bandIndex = index < 8 ? index : (15 - index)
        let rawBand = bandIndex < spectralBands.count ? spectralBands[bandIndex] : 0.1
        let scaled = CGFloat(rawBand) * 75.0 + CGFloat(audioPower) * 20.0
        return min(max(scaled, 8.0), 85.0)
    }
    
    private func barTopColor(for index: Int) -> Color {
        if !isActive { return Color.white.opacity(0.2) }
        return (index == 7 || index == 8) ? AppTheme.executiveGold : AppTheme.cyberCyan
    }
    
    private func barBottomColor(for index: Int) -> Color {
        if !isActive { return Color.white.opacity(0.06) }
        return AppTheme.cyberCyan.opacity(0.4)
    }
}
