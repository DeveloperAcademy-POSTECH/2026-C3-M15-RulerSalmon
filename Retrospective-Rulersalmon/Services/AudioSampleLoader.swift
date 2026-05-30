import AVFoundation
import Foundation

enum AudioSampleLoader {
    static func loadMonoFloatSamples(from url: URL, targetSampleRate: Double) throws -> [Float] {
        let inputFile = try AVAudioFile(forReading: url)
        let inputFormat = inputFile.processingFormat

        guard let outputFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: targetSampleRate,
            channels: 1,
            interleaved: false
        ) else {
            throw CocoaError(.coderInvalidValue)
        }

        let ratio = targetSampleRate / inputFormat.sampleRate
        let outputFrameCapacity = AVAudioFrameCount(Double(inputFile.length) * ratio) + 1024

        guard
            let inputBuffer = AVAudioPCMBuffer(
                pcmFormat: inputFormat,
                frameCapacity: AVAudioFrameCount(inputFile.length)
            ),
            let outputBuffer = AVAudioPCMBuffer(
                pcmFormat: outputFormat,
                frameCapacity: outputFrameCapacity
            ),
            let converter = AVAudioConverter(from: inputFormat, to: outputFormat)
        else {
            throw CocoaError(.coderInvalidValue)
        }

        try inputFile.read(into: inputBuffer)

        var didProvideInput = false
        var conversionError: NSError?
        converter.convert(to: outputBuffer, error: &conversionError) { _, status in
            if didProvideInput {
                status.pointee = .noDataNow
                return nil
            }
            didProvideInput = true
            status.pointee = .haveData
            return inputBuffer
        }

        if let conversionError {
            throw conversionError
        }

        guard let channel = outputBuffer.floatChannelData?[0] else {
            throw CocoaError(.coderInvalidValue)
        }

        let frameCount = Int(outputBuffer.frameLength)
        return Array(UnsafeBufferPointer(start: channel, count: frameCount))
    }
}
