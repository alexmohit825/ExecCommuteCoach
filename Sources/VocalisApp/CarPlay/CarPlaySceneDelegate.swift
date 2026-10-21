// CarPlaySceneDelegate.swift
// Native Apple CarPlay Scene Delegate for ExecCommuteCoach
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
        
        // Ensure CarAudioDirector configures duplex cabin Bluetooth / CarPlay audio
        try? CarAudioDirector.shared.configureSession()

        let rootTemplate = buildCarPlayRootTemplate()
        interfaceController.setRootTemplate(rootTemplate, animated: true, completion: nil)

        // Observe session updates to refresh dashboard telemetry
        ExecutiveSessionManager.shared.$isSessionActive
            .combineLatest(ExecutiveSessionManager.shared.$liveWPM, ExecutiveSessionManager.shared.$totalFillers)
            .debounce(for: .milliseconds(400), scheduler: RunLoop.main)
            .sink { [weak self] _, _, _ in
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
                ? "\(session.liveWPM) WPM • \(session.totalFillers) Fillers • \(session.selectedFramework.name)"
                : "Eyes-Free Verbal Coaching • Tap to begin"
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
                detailText: "Fillers: \(session.totalFillers) | Pitch: \(String(format: "%.0f Hz", session.fundamentalPitchHz))"
            )
            liveItems.append(statusItem)
            
            if !session.activeFrictionAlert.isEmpty {
                let pushbackItem = CPListItem(
                    text: "⚡ Pushback: \(session.activeFrictionAlert)",
                    detailText: "Stay calm • Maintain chest resonance"
                )
                liveItems.append(pushbackItem)
            }
        }
        
        sections.append(CPListSection(items: liveItems, header: "Commute Speech Telemetry", sectionIndexTitle: nil))

        // 2. Executive Frameworks (Oratey)
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

        // 3. Quick Vocal Drills (Speak-Up)
        let pushbackItem = CPListItem(
            text: "⚡ Trigger Boardroom Pushback",
            detailText: "Simulate immediate executive interruption"
        )
        pushbackItem.handler = { [weak self] _, completion in
            Task { @MainActor in
                session.selectedFramework = FrameworkCatalog.all.first(where: { $0.id == "friction" }) ?? session.selectedFramework
                if !session.isSessionActive {
                    session.startSession()
                }
                completion()
                self?.refreshTemplate()
            }
        }
        
        sections.append(CPListSection(items: [pushbackItem], header: "Stress-Test Drills", sectionIndexTitle: nil))

        let listTemplate = CPListTemplate(
            title: "ExecCommuteCoach",
            sections: sections
        )
        return listTemplate
    }

    private func refreshTemplate() {
        guard let ic = interfaceController else { return }
        let updated = buildCarPlayRootTemplate()
        ic.setRootTemplate(updated, animated: false, completion: nil)
    }
}
