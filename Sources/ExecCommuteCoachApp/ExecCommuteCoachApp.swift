// ExecCommuteCoachApp.swift
// ExecCommuteCoach Main Application Entry Point
import SwiftUI
import Speech

@main
struct ExecCommuteCoachApp: App {
    @StateObject private var sessionManager = ExecutiveSessionManager.shared
    
    init() {
        try? CarAudioDirector.shared.configureSession()
        SFSpeechRecognizer.requestAuthorization { _ in }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sessionManager)
                .preferredColorScheme(.dark)
        }
    }
}
