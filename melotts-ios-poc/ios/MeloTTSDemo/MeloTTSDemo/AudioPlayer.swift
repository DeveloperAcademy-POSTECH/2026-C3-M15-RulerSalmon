import AVFoundation
import Foundation

final class AudioPlayer {
    private var player: AVAudioPlayer?

    func play(fileURL: URL) throws {
        player = try AVAudioPlayer(contentsOf: fileURL)
        player?.prepareToPlay()
        player?.play()
    }
}
