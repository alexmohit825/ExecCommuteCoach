// FrictionCoachEngineWrapper.swift
import Foundation
import SwiftUI

final class FrictionCoachEngineWrapper: ObservableObject {
    private let engine = FrictionCoachEngine()
    @Published var lastPrompt: String = ""
    
    func start(mode: FrictionCoachEngine.Mode = .prep) {
        engine.start(mode: mode) { [weak self] phrase in
            DispatchQueue.main.async {
                self?.lastPrompt = phrase
            }
        }
    }
    
    func stop() { engine.stop() }
    
    deinit { engine.stop() }
}
