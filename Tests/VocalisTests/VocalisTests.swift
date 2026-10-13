// Tests/VocalisTests/VocalisTests.swift
import XCTest
@testable import VocalisApp

final class VocalisTests: XCTestCase {
    func testFrameworkCatalogHasCoreArchetypes() {
        let frameworks = FrameworkCatalog.all
        XCTAssertGreaterThanOrEqual(frameworks.count, 4, "Should offer PREP, STAR, Pyramid Principle, and Boardroom Pushback")
        
        let ids = Set(frameworks.map { $0.id })
        XCTAssertTrue(ids.contains("prep"), "PREP framework missing")
        XCTAssertTrue(ids.contains("star"), "STAR framework missing")
        XCTAssertTrue(ids.contains("pyramid"), "Pyramid Principle missing")
        XCTAssertTrue(ids.contains("friction"), "Adversarial Pushback missing")
    }
    
    func testSpeechTelemetryStandardFillersCatalog() {
        let fillers = SpeechTelemetryEngine.standardFillers
        XCTAssertTrue(fillers.contains("um"), "Catalog must include 'um'")
        XCTAssertTrue(fillers.contains("uh"), "Catalog must include 'uh'")
        XCTAssertTrue(fillers.contains("like"), "Catalog must include 'like'")
        XCTAssertTrue(fillers.contains("you know"), "Catalog must include 'you know'")
        XCTAssertTrue(fillers.contains("actually"), "Catalog must include 'actually'")
        XCTAssertTrue(fillers.contains("basically"), "Catalog must include 'basically'")
    }
    
    func testBreathingPacerIntervals() {
        let box = BreathingMode.box.intervals
        XCTAssertEqual(box.inhale, 4.0)
        XCTAssertEqual(box.hold1, 4.0)
        XCTAssertEqual(box.exhale, 4.0)
        XCTAssertEqual(box.hold2, 4.0)
        
        let calm = BreathingMode.calm.intervals
        XCTAssertEqual(calm.inhale, 4.0)
        XCTAssertEqual(calm.hold1, 7.0)
        XCTAssertEqual(calm.exhale, 8.0)
    }
    
    @MainActor
    func testExecutiveReadinessScoreBoundaryConditions() {
        let manager = ExecutiveSessionManager()
        let initialScore = manager.calculateReadinessScore()
        XCTAssertGreaterThanOrEqual(initialScore, 15)
        XCTAssertLessThanOrEqual(initialScore, 100)
    }
}
