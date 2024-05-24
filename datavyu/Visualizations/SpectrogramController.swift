import Foundation
import AppKit
import AVFoundation
import MediaToolbox

/*
 TODO: Set this up as its own AVPlayer that is slightly ahead of the video
 then put the images into a queue with the timestamp attached, pull them
 as the video plays.
 
 */

protocol VideoMediaInputDelegate: AnyObject {
    func videoFrameRefresh(sampleBuffer: CMSampleBuffer) //could be audio or video
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
        self.spectrogram = AudioSpectrogram()
        self.outputImage = NSImage(size: NSSize(width: 100, height: 100)) // Create placeholder
        
        super.init()
        self.player.isMeteringEnabled = true
        
//        player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.01, preferredTimescale: CMTimeScale(600)), queue: nil) { time in
//            player.audioPCMBufferFetched { pcmBuffer, fetched in
//                DispatchQueue.main.async {
//                    if pcmBuffer != nil {
//                        self.spectrogram.processBuffer(pcmBuffer: pcmBuffer!)
//                        self.outputImage = self.formatImage(image: self.spectrogram.outputImage)
//                                                
//                        print("Created image: \(self.outputImage.size)")
//                        self.updates += 1
//                    }
//                }
//            }
//        }
        

        
    }
    
    func createVideoFile() {
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func formatImage(image: CGImage) -> NSImage {
//        print(image.dataProvider?.data)
        let size = NSSize(width: image.width, height: image.height)
        return NSImage(cgImage: image, size: size)
    }
    
    func audioBufferToBytes(audioBuffer: AVAudioPCMBuffer) -> [Int16] {
        let srcLeft = audioBuffer.floatChannelData![0]
        let bytesPerFrame = audioBuffer.format.streamDescription.pointee.mBytesPerFrame
        let numBytes = Int(bytesPerFrame * audioBuffer.frameLength)
        
        // initialize bytes by 0
        var audioByteArray = [Int16](repeating: 0, count: numBytes)
        
        srcLeft.withMemoryRebound(to: Int16.self, capacity: numBytes) { srcByteData in
            audioByteArray.withUnsafeMutableBufferPointer {
                $0.baseAddress!.initialize(from: srcByteData, count: numBytes)
            }
        }
        
        return audioByteArray
    }
    
    
}
