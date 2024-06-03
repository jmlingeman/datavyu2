import AppKit
import AVFoundation
import Foundation
import MediaToolbox

/*
 TODO: Set this up as its own AVPlayer that is slightly ahead of the video
 then put the images into a queue with the timestamp attached, pull them
 as the video plays.

 */

protocol VideoMediaInputDelegate: AnyObject {
    func videoFrameRefresh(sampleBuffer: CMSampleBuffer) // could be audio or video
}

struct SpectrogramData {
    var time: CMTime
    var image: NSImage
}

class SpectrogramController: NSResponder, NSApplicationDelegate, ObservableObject {
    @Published var player: AVPlayer
    @Published var spectrogram: AudioSpectrogram
    @Published var outputImage: NSImage
    @Published var updates = 0

    init(player: AVPlayer) {
        self.player = player
        spectrogram = AudioSpectrogram()
        outputImage = NSImage(size: NSSize(width: 100, height: 100)) // Create placeholder

        super.init()
        self.player.isMeteringEnabled = true
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func formatImage(image: CGImage) -> NSImage {
        let size = NSSize(width: image.width, height: image.height)
        return NSImage(cgImage: image, size: size)
    }
}
