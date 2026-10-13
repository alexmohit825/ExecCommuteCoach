// AcousticTelemetryEngine.swift
// Real-time acoustic telemetry using AVAudioEngine and Accelerate FFT.
import AVFoundation
import Accelerate

final class AcousticTelemetryEngine {
    private let engine = AVAudioEngine()
    private let inputNode: AVAudioInputNode
    private let bus: AVAudioNodeBus = 0
    private let fftSetup: FFTSetup
    private let log2n: vDSP_Length = 10 // 1024-point FFT
    private let bufferSize: AVAudioFrameCount = 1024
    private var isRunning = false
    
    // Callback delivering: (frequencyHz, normalizedPower, spectralBands[8])
    var onAcousticUpdate: ((Float, Float, [Float]) -> Void)?
    
    init?() {
        self.inputNode = engine.inputNode
        guard let fft = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2)) else { return nil }
        self.fftSetup = fft
    }
    
    func start() throws {
        guard !isRunning else { return }
        
        let format = inputNode.inputFormat(forBus: bus)
        guard format.sampleRate > 0, format.channelCount > 0 else {
            throw NSError(domain: "AcousticTelemetry", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "No valid microphone input format available"])
        }
        
        let half = vDSP_Length(bufferSize / 2)
        inputNode.installTap(onBus: bus, bufferSize: bufferSize, format: format) { [weak self] buffer, _ in
            guard let self = self,
                  let channelData = buffer.floatChannelData?.pointee,
                  buffer.frameLength >= self.bufferSize else { return }
            
            // 1. Calculate RMS audio power (dB normalized to 0.0 ... 1.0)
            var rms: Float = 0.0
            vDSP_rmsqv(channelData, 1, &rms, vDSP_Length(buffer.frameLength))
            let power = min(max(rms * 12.0, 0.0), 1.0) // Scaled for speech dynamics
            
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
                    
                    // Peak frequency calculation within human speech range (85 Hz to 400 Hz)
                    var maxMag: Float = 0
                    var maxIndex: vDSP_Length = 0
                    vDSP_maxvi(magnitudes, 1, &maxMag, &maxIndex, vDSP_Length(magnitudes.count))
                    
                    let nyquist = 0.5 * Float(format.sampleRate)
                    let freq = Float(maxIndex) * nyquist / Float(half)
                    
                    // 8-Band spectral reduction for fluid UI waveform rendering
                    var bands = [Float](repeating: 0.0, count: 8)
                    let bandWidth = Int(half) / 8
                    for i in 0..<8 {
                        let startIdx = i * bandWidth
                        let endIdx = min(startIdx + bandWidth, Int(half))
                        let slice = magnitudes[startIdx..<endIdx]
                        let avg = slice.reduce(0, +) / Float(max(1, slice.count))
                        // Compress logarithmically for visual appeal
                        bands[i] = min(max(sqrt(avg) * 0.15, 0.05), 1.0)
                    }
                    
                    self.onAcousticUpdate?(freq, power, bands)
                }
            }
        }
        
        try engine.start()
        isRunning = true
    }
    
    func stop() {
        guard isRunning else { return }
        engine.stop()
        inputNode.removeTap(onBus: bus)
        isRunning = false
    }
    
    deinit {
        vDSP_destroy_fftsetup(fftSetup)
    }
}
