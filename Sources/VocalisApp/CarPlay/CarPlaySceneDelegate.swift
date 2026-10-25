// CarPlaySceneDelegate.swift
// Native Apple CarPlay Scene Delegate for ExecCommuteCoach 2.0
import Foundation
import CarPlay
import UIKit
import Combine

@MainActor
final class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    var interfaceController: CPInterfaceController?
    private var cancellables = Set<AnyCancellable>()

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        self.interfaceController = interfaceController
        
        try? CarAudioDirector.shared.configureSession()

        let rootTemplate = buildCarPlayRootTemplate()
        interfaceController.setRootTemplate(rootTemplate, animated: true, completion: nil)

        // Observe session updates to refresh dashboard telemetry
        Publishers.CombineLatest4(
            ExecutiveSessionManager.shared.$isSessionActive,
            ExecutiveSessionManager.shared.$liveWPM,
            ExecutiveSessionManager.shared.$totalFillers,
            ExecutiveSessionManager.shared.$totalHedgings
        )
        .debounce(for: .milliseconds(400), scheduler: RunLoop.main)
        .sink { [weak self] _, _, _, _ in
            guard let self = self, let ic = self.interfaceController else { return }
            let updatedRoot = self.buildCarPlayRootTemplate()
            ic.setRootTemplate(updatedRoot, animated: false, completion: nil)
        }
        .store(in: &cancellables)
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        try? CarAudioDirector.shared.configureSession()
    }

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnectInterfaceController interfaceController: CPInterfaceController
    ) {
        self.interfaceController = nil
        cancellables.removeAll()
    }

    private func buildCarPlayRootTemplate() -> CPTemplate {
        let session = ExecutiveSessionManager.shared
        var sections: [CPListSection] = []

        // 1. Live Commute Session Control Section
        let sessionActive = session.isSessionActive
        let mainControlItem = CPListItem(
            text: sessionActive ? "⏹️ End Coaching & Review Scorecard" : "🎙️ Start Commute Voice Coaching",
            detailText: sessionActive
                ? "\(session.liveWPM) WPM • \(session.totalFillers) Fillers • \(session.totalHedgings) Hedges"
                : "Hands-Free Executive Coaching • Tap to begin"
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
                    detailText: "Hold steady cadence • Address directly"
                )
                liveItems.append(pushbackItem)
            }
        }
        
        sections.append(CPListSection(items: liveItems, header: "Commute Speech Telemetry", sectionIndexTitle: nil))

        // 2. AI Boardroom Personas
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

        // 3. Executive Frameworks (Oratey)
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

        let template = CPListTemplate(title: "ExecCommuteCoach", sections: sections)
        return template
    }

    private func refreshTemplate() {
        guard let ic = interfaceController else { return }
        let updated = buildCarPlayRootTemplate()
        ic.setRootTemplate(updated, animated: false, completion: nil)
    }
}
