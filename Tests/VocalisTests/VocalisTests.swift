// Tests/VocalisTests/VocalisTests.swift
import XCTest
@testable import VocalisApp

final class VocalisTests: XCTestCase {
    func testAcousticEngineInitialFrequencyIsZero() {
        let wrapper = AcousticTelemetryEngineWrapper()
        XCTAssertEqual(wrapper.frequency, 0.0, "Initial frequency should be zero before audio starts")
    }
    
    func testSpeechEngineInitialWPMIsZero() {
        let wrapper = SpeechTelemetryEngineWrapper()
        XCTAssertEqual(wrapper.wpm, 0, "Initial WPM should be zero before speech starts")
    }
}
