// AcousticTelemetryEngine.swift
// Pure DSP acoustic telemetry using Accelerate FFT, with pitch variance and modulation grading.
// Decoupled from hardware I/O; receives buffers from AudioPipelineEngine.
import AVFoundation
import Accelerate

final class AcousticTelemetryEngine {
    private let fftSetup: FFTSetup
    private let log2n: vDSP_Length = 10 // 1024-point FFT
    private let bufferSize: AVAudioFrameCount = 1024
    
    // Sliding pitch history for dynamic modulation analysis
    private var pitchHistory: [Float] = []
    private let maxHistory = 150
    
    // Callbacks delivering: (frequencyHz, normalizedPower, spectralBands[8])
    var onAcousticUpdate: ((Float, Float, [Float]) -> Void)?
    var onModulationUpdate: ((Float, String) -> Void)? // (stdDevHz, grade)
    
    init?() {
        guard let fft = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2)) else { return nil }
        self.fftSetup = fft
    }
    
    deinit {
        vDSP_destroy_fftsetup(fftSetup)
    }
    
    func reset() {
        pitchHistory.removeAll()
    }
    
    func processBuffer(_ buffer: AVAudioPCMBuffer, sampleRate: Double) {
        guard let channelData = buffer.floatChannelData?.pointee,
              buffer.frameLength >= self.bufferSize else { return }
        
        let half = vDSP_Length(bufferSize / 2)
        
        // 1. Calculate RMS audio power
        var rms: Float = 0.0
        vDSP_rmsqv(channelData, 1, &rms, vDSP_Length(buffer.frameLength))
        let power = min(max(rms * 12.0, 0.0), 1.0)
        
        // 2. Perform FFT for pitch and spectral envelope
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
                
                // Peak frequency calculation within speech range (85 Hz to 380 Hz)
                var maxMag: Float = 0
                var maxIndex: vDSP_Length = 0
                vDSP_maxvi(magnitudes, 1, &maxMag, &maxIndex, vDSP_Length(magnitudes.count))
                
                let nyquist = 0.5 * Float(sampleRate > 0 ? sampleRate : 44100.0)
                let freq = Float(maxIndex) * nyquist / Float(half)
                
                // 8-Band spectral reduction
                var bands = [Float](repeating: 0.0, count: 8)
                let bandWidth = Int(half) / 8
                for i in 0..<8 {
                    let startIdx = i * bandWidth
                    let endIdx = min(startIdx + bandWidth, Int(half))
                    let slice = magnitudes[startIdx..<endIdx]
                    let avg = slice.reduce(0, +) / Float(max(1, slice.count))
                    bands[i] = min(max(sqrt(avg) * 0.15, 0.05), 1.0)
                }
                
                // Pitch stability & dynamic modulation
                if power > 0.08 && freq >= 80.0 && freq <= 360.0 {
                    self.pitchHistory.append(freq)
                    if self.pitchHistory.count > self.maxHistory {
                        self.pitchHistory.removeFirst()
                    }
                    
                    if self.pitchHistory.count >= 20 {
                        let (stdDev, grade) = self.calculateModulation()
                        self.onModulationUpdate?(stdDev, grade)
                    }
                }
                
                self.onAcousticUpdate?(freq, power, bands)
            }
        }
    }
    
    private func calculateModulation() -> (Float, String) {
        guard pitchHistory.count > 1 else { return (0.0, "Calibrating") }
        let count = Float(pitchHistory.count)
        let mean = pitchHistory.reduce(0, +) / count
        let variance = pitchHistory.map { pow($0 - mean, 2) }.reduce(0, +) / count
        let stdDev = sqrt(variance)
        
        let grade: String
        if stdDev >= 22.0 {
            grade = "Dynamic & Commanding"
        } else if stdDev >= 12.0 {
            grade = "Steady Executive"
        } else {
            grade = "Monotone / Droning"
        }
        return (stdDev, grade)
    }
}
