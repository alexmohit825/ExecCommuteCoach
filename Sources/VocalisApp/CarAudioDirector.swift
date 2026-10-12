// CarAudioDirector.swift
import AVFoundation
import UIKit

/// Configures AVAudioSession for in‑vehicle Bluetooth and CarPlay audio routing.
final class CarAudioDirector {
    static let shared = CarAudioDirector()
    private init() {}
    
    /// Call this at app launch to enable duplex audio for coaching.
    func configureSession() throws {
        let session = AVAudioSession.sharedInstance()
        // Enable recording + playback, allow Bluetooth (HFP) and CarPlay.
        try session.setCategory(.playAndRecord,
                                 mode: .default,
                                 options: [.allowBluetooth, .allowBluetoothA2DP, .duckOthers, .defaultToSpeaker])
        // Prefer CarPlay audio route when available.
        if #available(iOS 16.0, *) {
            try session.setPrefersNoInterruptionsFromSystemAlerts(true)
        }
        try session.setActive(true, options: .notifyOthersOnDeactivation)
    }
}
