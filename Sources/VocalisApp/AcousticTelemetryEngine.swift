// AcousticTelemetryEngine.swift
import AVFoundation
import Accelerate

/// Real‑time acoustic telemetry using AVAudioEngine and Accelerate FFT.
final class AcousticTelemetryEngine {
    private let engine = AVAudioEngine()
    private let inputNode: AVAudioInputNode
    private let bus: AVAudioNodeBus = 0
    private let fftSetup: FFTSetup
    private let log2n: vDSP_Length = 10 // 1024‑point FFT
    private let bufferSize: AVAudioFrameCount = 1024
    
    init?() {
        self.inputNode = engine.inputNode
        guard let fft = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2)) else { return nil }
        self.fftSetup = fft
    }
    
    /// Starts the audio engine and installs a tap to compute fundamental frequency.
    func start(completion: @escaping (Float) -> Void) throws {
        let format = inputNode.inputFormat(forBus: bus)
        guard format.sampleRate > 0, format.channelCount > 0 else {
            throw NSError(domain: "AcousticTelemetry", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "No valid microphone input format"])
        }
        let half = vDSP_Length(bufferSize / 2)
        inputNode.installTap(onBus: bus, bufferSize: bufferSize, format: format) { buffer, _ in
            guard let channelData = buffer.floatChannelData?.pointee,
                  buffer.frameLength >= self.bufferSize else { return }
            var realp = [Float](repeating: 0, count: Int(half))
            var imagp = [Float](repeating: 0, count: Int(half))
            realp.withUnsafeMutableBufferPointer { realPtr in
                imagp.withUnsafeMutableBufferPointer { imagPtr in
                    var splitComplex = DSPSplitComplex(realp: realPtr.baseAddress!, imagp: imagPtr.baseAddress!)
                    channelData.withMemoryRebound(to: DSPComplex.self, capacity: Int(half)) { typeConvertedTransferBuffer in
                        vDSP_ctoz(typeConvertedTransferBuffer, 2, &splitComplex, 1, half)
                    }
                    vDSP_fft_zrip(self.fftSetup, &splitComplex, 1, self.log2n, FFTDirection(FFT_FORWARD))
                    var magnitudes = [Float](repeating: 0.0, count: Int(half))
                    vDSP_zvmags(&splitComplex, 1, &magnitudes, 1, half)
                    // Find peak bin
                    var maxMag: Float = 0
                    var maxIndex: vDSP_Length = 0
                    vDSP_maxvi(magnitudes, 1, &maxMag, &maxIndex, vDSP_Length(magnitudes.count))
                    // Convert bin to frequency (Hz)
                    let nyquist = 0.5 * Float(format.sampleRate)
                    let freq = Float(maxIndex) * nyquist / Float(self.bufferSize/2)
                    completion(freq)
                }
            }
        }
        try engine.start()
    }
    
    func stop() {
        engine.stop()
        inputNode.removeTap(onBus: bus)
    }
    deinit { vDSP_destroy_fftsetup(fftSetup) }
}
