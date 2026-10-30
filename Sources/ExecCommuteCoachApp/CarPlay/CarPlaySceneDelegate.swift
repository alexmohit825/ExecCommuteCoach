// CarPlaySceneDelegate.swift
// Crash-resilient Apple CarPlay Scene Delegate for ExecCommuteCoach.
// Enforces Apple HIG driver-safety standards and eliminates 400ms IPC template thrashing.
import Foundation
import CarPlay
import UIKit
import Combine

@MainActor
final class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    var interfaceController: CPInterfaceController?
    private var rootListTemplate: CPListTemplate?
    private var cancellables = Set<AnyCancellable>()

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        self.interfaceController = interfaceController
        
        try? CarAudioDirector.shared.configureSession()

        let template = buildCarPlayRootTemplate()
        self.rootListTemplate = template
        interfaceController.setRootTemplate(template, animated: true, completion: nil)

        setupSafeStateObservation()
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        try? CarAudioDirector.shared.configureSession()
    }

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnectInterfaceController interfaceController: CPInterfaceController
    ) {
        self.interfaceController = nil
        self.rootListTemplate = nil
        cancellables.removeAll()
    }

    private func setupSafeStateObservation() {
        cancellables.removeAll()
        let session = ExecutiveSessionManager.shared

        // 1. Immediate refresh on session start/stop toggle
        session.$isSessionActive
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.refreshTemplate()
            }
            .store(in: &cancellables)

        // 2. Immediate refresh on incoming AI Pushback Alert
        session.$activeFrictionAlert
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.refreshTemplate()
            }
            .store(in: &cancellables)

        // 3. Calm 5-second telemetry heartbeat (prevents CarPlay IPC bus flooding & watchdog kills)
        Timer.publish(every: 5.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, session.isSessionActive else { return }
                self.refreshTemplate()
            }
            .store(in: &cancellables)
    }

    private func buildCarPlayRootTemplate() -> CPListTemplate {
        let session = ExecutiveSessionManager.shared
        let sections = buildSections(for: session)
        let template = CPListTemplate(title: "ExecCommuteCoach", sections: sections)
        return template
    }

    private func buildSections(for session: ExecutiveSessionManager) -> [CPListSection] {
        var sections: [CPListSection] = []

        // Section 1: Hands-Free Commute Coaching Controls & Telemetry
        let sessionActive = session.isSessionActive
        let mainControlItem = CPListItem(
            text: sessionActive ? "⏹️ End Coaching & View Scorecard" : "🎙️ Start Commute Coaching",
            detailText: sessionActive
                ? "\(session.liveWPM) WPM • \(session.totalFillers) Fillers • \(session.totalHedgings) Hedges"
                : "Hands-Free Voice Rehearsal • Tap to begin"
        )
        mainControlItem.handler = { [weak self] _, completion in
            Task { @MainActor in
                if session.isSessionActive {
                    session.endSession()
                } else {
                    session.startSession()
                }
                completion()
                self?.refreshTemplate()
            }
        }
        
        var liveItems = [mainControlItem]
        
        if sessionActive {
            let statusItem = CPListItem(
                text: "Cadence: \(session.liveWPM) WPM (\(session.cadenceZone.rawValue))",
                detailText: "\(session.totalFillers) Fillers • \(session.totalHedgings) Hedges • \(session.strategicPauses) Pauses"
            )
            liveItems.append(statusItem)
            
            if !session.activeFrictionAlert.isEmpty {
                let pushbackItem = CPListItem(
                    text: "⚡ \(session.activePersona.rawValue): \(session.activeFrictionAlert)",
                    detailText: "Chest resonance • Maintain steady pace"
                )
                liveItems.append(pushbackItem)
            }
        }
        
        sections.append(CPListSection(items: liveItems, header: "Commute Presence Telemetry", sectionIndexTitle: nil))

        // Section 2: AI Sparring Persona Selector
        let personaItems: [CPListItem] = BoardroomPersona.allCases.map { persona in
            let isSelected = session.activePersona == persona
            let item = CPListItem(
                text: isSelected ? "✓ \(persona.rawValue)" : persona.rawValue,
                detailText: persona.subtitle
            )
            item.handler = { [weak self] _, completion in
                Task { @MainActor in
                    session.activePersona = persona
                    completion()
                    self?.refreshTemplate()
                }
            }
            return item
        }
        sections.append(CPListSection(items: personaItems, header: "AI Sparring Persona", sectionIndexTitle: nil))

        // Section 3: Executive Speaking Frameworks (Oratey)
        let frameworkItems: [CPListItem] = FrameworkCatalog.all.map { framework in
            let isSelected = session.selectedFramework.id == framework.id
            let item = CPListItem(
                text: isSelected ? "✓ \(framework.name)" : framework.name,
                detailText: "\(framework.category) • \(framework.overview)"
            )
            item.handler = { [weak self] _, completion in
                Task { @MainActor in
                    session.selectedFramework = framework
                    completion()
                    self?.refreshTemplate()
                }
            }
            return item
        }
        sections.append(CPListSection(items: frameworkItems, header: "Executive Frameworks", sectionIndexTitle: nil))

        return sections
    }

    private func refreshTemplate() {
        guard let session = Optional(ExecutiveSessionManager.shared) else { return }
        let newSections = buildSections(for: session)
        
        if let current = rootListTemplate {
            current.updateSections(newSections)
        } else if let ic = interfaceController {
            let newTemplate = CPListTemplate(title: "ExecCommuteCoach", sections: newSections)
            self.rootListTemplate = newTemplate
            ic.setRootTemplate(newTemplate, animated: false, completion: nil)
        }
    }
}
