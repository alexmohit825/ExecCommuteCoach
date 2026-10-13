// Theme.swift
// ExecCommuteCoach Executive Design System (Inspired by Well-Spoken & Speeko)
import SwiftUI

public enum AppTheme {
    // MARK: - Color Palette
    public static let background = Color(red: 0.04, green: 0.05, blue: 0.08)       // #0A0D14 Midnight Obsidian
    public static let surface = Color(red: 0.08, green: 0.10, blue: 0.15)          // #141A26 Elevated Charcoal
    public static let surfaceLight = Color(red: 0.12, green: 0.15, blue: 0.22)     // #1F2638 Glass Rim
    
    // Accents
    public static let executiveGold = Color(red: 0.86, green: 0.72, blue: 0.38)    // #DDB861 Champagne Gold
    public static let cyberCyan = Color(red: 0.00, green: 0.85, blue: 0.95)        // #00D9F2 Electric Cyan
    public static let emeraldGreen = Color(red: 0.15, green: 0.82, blue: 0.55)     // #26D18C Cadence Green
    public static let coralAlert = Color(red: 0.98, green: 0.38, blue: 0.38)       // #FA6161 Filler Warning
    public static let electricIndigo = Color(red: 0.45, green: 0.35, blue: 0.95)   // #7359F2 Framework Accent
    
    public static let textPrimary = Color.white
    public static let textSecondary = Color(white: 0.65)
    public static let textTertiary = Color(white: 0.42)
    
    // MARK: - Gradients
    public static let backgroundGradient = LinearGradient(
        colors: [
            Color(red: 0.04, green: 0.05, blue: 0.09),
            Color(red: 0.06, green: 0.07, blue: 0.12),
            Color(red: 0.02, green: 0.03, blue: 0.05)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    public static let goldGradient = LinearGradient(
        colors: [Color(red: 0.95, green: 0.82, blue: 0.48), Color(red: 0.75, green: 0.60, blue: 0.28)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    public static let cyanGradient = LinearGradient(
        colors: [Color(red: 0.00, green: 0.92, blue: 1.00), Color(red: 0.00, green: 0.60, blue: 0.90)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    public static let cardGlass = LinearGradient(
        colors: [
            Color.white.opacity(0.08),
            Color.white.opacity(0.02)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - View Modifiers
struct GlassCardModifier: ViewModifier {
    var strokeColor: Color = Color.white.opacity(0.12)
    var cornerRadius: CGFloat = 20
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(AppTheme.cardGlass)
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(AppTheme.surface.opacity(0.65))
                            .blur(radius: 20)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(strokeColor, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.35), radius: 12, x: 0, y: 6)
    }
}

extension View {
    func glassCard(strokeColor: Color = Color.white.opacity(0.12), cornerRadius: CGFloat = 20) -> some View {
        self.modifier(GlassCardModifier(strokeColor: strokeColor, cornerRadius: cornerRadius))
    }
}
