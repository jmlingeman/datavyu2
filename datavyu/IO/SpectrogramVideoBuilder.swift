// https://github.com/acj/TimeLapseBuilder-Swift/blob/main/TimeLapseBuilder-Common/TimeLapseBuilder.swift

import AVFoundation
import CoreImage
import SwiftUI

#if os(macOS)
import Cocoa
typealias UIImage = NSImage
#else
import UIKit
#endif

let kErrorDomain = "TimeLapseBuilder"
let kFailedToStartAssetWriterError = 0
let kFailedToAppendPixelBufferError = 1
let kFailedToDetermineAssetDimensions = 2
let kFailedToProcessAssetPath = 3

public protocol SpectrogramVideoBuilderDelegate: AnyObject {
    func timeLapseBuilder(_ timelapseBuilder: SpectrogramVideoBuilder, didMakeProgress progress: Progress)
    func timeLapseBuilder(_ timelapseBuilder: SpectrogramVideoBuilder, didFinishWithURL url: URL)
    func timeLapseBuilder(_ timelapseBuilder: SpectrogramVideoBuilder, didFailWithError error: Error)
}

class SpectrogramDelegate: SpectrogramVideoBuilderDelegate {
    var didMakeProgress: ((Progress) -> Void)?
    var didFinish: ((URL) -> Void)?
    var didFailWithError: ((Error) -> Void)?
    
    init(progress: ((Progress) -> Void)?, finished: ((URL) -> Void)?, failed: ((Error) -> Void)?) {
        self.didMakeProgress = progress
        self.didFinish = finished
        self.didFailWithError = failed
    }
    
    func timeLapseBuilder(_ timelapseBuilder: SpectrogramVideoBuilder, didMakeProgress progress: Progress) {
        self.didMakeProgress?(progress)
    }
    
    func timeLapseBuilder(_ timelapseBuilder: SpectrogramVideoBuilder, didFinishWithURL url: URL) {
        self.didFinish?(url)
    }
    
    func timeLapseBuilder(_ timelapseBuilder: SpectrogramVideoBuilder, didFailWithError error: Error) {
        self.didFailWithError?(error)
    }
}


public class SpectrogramVideoBuilder: ObservableObject {
    @Published var progress = 0.0
    
    public var delegate: SpectrogramVideoBuilderDelegate
    
    var videoWriter: AVAssetWriter?
    
    public init(delegate: SpectrogramVideoBuilderDelegate?) {
        if delegate == nil {
            self.delegate = SpectrogramDelegate { progress in
                
            } finished: { url in
                
            } failed: { error in
                print(error)
            }
        } else {
            self.delegate = delegate!
        }
    }
    
    public func build(with player: AVPlayer, atFrameRate framesPerSecond: Int32, type: AVFileType, toOutputPath: String) {
        // Output video dimensions are inferred from the first image asset
        do {
            if player.currentItem != nil {
                let asset = player.currentItem!.asset
                
                let totalTime = asset.duration.seconds
                
                let assetReader = try AVAssetReader(asset: asset)
                
                // Abort if no audio track, cant make a spectrogram
                guard let audioTrack = player.currentItem!.asset.tracks(withMediaType: AVMediaType.audio).first else {
                    return
                }
                let spectrogramController = SpectrogramController(player: player)
                let spectrogram = spectrogramController.spectrogram
                
                let audioSettings: [String: Any] = [
                    AVFormatIDKey: kAudioFormatLinearPCM,
                    AVSampleRateKey: 44100.0,
                    AVNumberOfChannelsKey: 1,
                    AVLinearPCMBitDepthKey: 16,
                    AVLinearPCMIsFloatKey: false,
                    AVLinearPCMIsBigEndianKey: false,
                    AVLinearPCMIsNonInterleaved: false
                ]
                let assetReaderAudioOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: audioSettings)
                
                if assetReader.canAdd(assetReaderAudioOutput) {
                    assetReader.add(assetReaderAudioOutput)
                } else {
                    fatalError("could not add audio output reader")
                }
                
                let canvasSize = AudioSpectrogram.canvasSize
        
                var error: NSError?
                let videoOutputURL = URL(fileURLWithPath: toOutputPath)
        
                do {
                    try FileManager.default.removeItem(at: videoOutputURL)
                } catch {}
        
                do {
                    try videoWriter = AVAssetWriter(outputURL: videoOutputURL, fileType: type)
                } catch let writerError as NSError {
                    error = writerError
                    videoWriter = nil
                }
        
                if let videoWriter = videoWriter {
                    let videoSettings: [String: AnyObject] = [
                        AVVideoCodecKey: AVVideoCodecType.h264 as AnyObject,
                        AVVideoWidthKey: canvasSize.width as AnyObject,
                        AVVideoHeightKey: canvasSize.height as AnyObject,
                        //        AVVideoCompressionPropertiesKey : [
                        //          AVVideoAverageBitRateKey : NSInteger(1000000),
                        //          AVVideoMaxKeyFrameIntervalKey : NSInteger(16),
                        //          AVVideoProfileLevelKey : AVVideoProfileLevelH264BaselineAutoLevel
                        //        ]
                    ]
            
                    let videoWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoSettings)
            
                    let sourceBufferAttributes = [
                        kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32ARGB),
                        kCVPixelBufferWidthKey as String: Float(canvasSize.width),
                        kCVPixelBufferHeightKey as String: Float(canvasSize.height),
                        kCVPixelBufferCGImageCompatibilityKey as String: true,
                        kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
                    ] as [String: Any]
            
                    let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(
                        assetWriterInput: videoWriterInput,
                        sourcePixelBufferAttributes: sourceBufferAttributes
                    )
            
                    assert(videoWriter.canAdd(videoWriterInput))
                    videoWriter.add(videoWriterInput)
                    
                    
                    
                    var frameCount: Int64 = 0
                        
                    
                    
                    if assetReader.startReading() && videoWriter.startWriting() {
                        videoWriter.startSession(atSourceTime: CMTime.zero)
                        assert(pixelBufferAdaptor.pixelBufferPool != nil)
                
                        let media_queue = DispatchQueue(label: "mediaInputQueue")
                
                        videoWriterInput.requestMediaDataWhenReady(on: media_queue) {
                            while videoWriterInput.isReadyForMoreMediaData {
//                                let presentationTime = CMTimeMake(value: frameCount, timescale: framesPerSecond)
                                
                                let sample = assetReaderAudioOutput.copyNextSampleBuffer()


                                if sample != nil {
                                    let presentationTime = CMSampleBufferGetPresentationTimeStamp(sample!)
                                    let image = spectrogram.processBuffer(sampleBuffer: sample!)
                                    let nsImage = spectrogramController.formatImage(image: image!)
                                    if !self.appendPixelBufferForNSImage(nsImage, pixelBufferAdaptor: pixelBufferAdaptor, presentationTime: presentationTime) {
                                        error = NSError(
                                            domain: kErrorDomain,
                                            code: kFailedToAppendPixelBufferError,
                                            userInfo: ["description": "AVAssetWriterInputPixelBufferAdapter failed to append pixel buffer"]
                                        )

                                        break
                                    }
                                    
                                    self.progress = presentationTime.seconds / totalTime
                                    print("PROGRESS: \(self.progress)")
                                    
                                    frameCount += 1

                                } else {
                                    videoWriterInput.markAsFinished()
                                    videoWriter.finishWriting {
                                        if let error = error {
                                            self.delegate.timeLapseBuilder(self, didFailWithError: error)
                                        } else {
                                            self.delegate.timeLapseBuilder(self, didFinishWithURL: videoOutputURL)
                                        }
                                        
                                        self.videoWriter = nil
                                    }
                                    assetReader.cancelReading()
                                    break
                                }
                            }
                    
                    
                            
                        }
                    } else {
                        
                        error = NSError(
                            domain: kErrorDomain,
                            code: kFailedToStartAssetWriterError,
                            userInfo: ["description": "AVAssetWriter failed to start writing"]
                        )
                        print("ERROR: \(error) \(videoWriter.status) \(videoWriter.error) \(assetReader.status) \(assetReader.error)")
                    }
                }
        
                if let error = error {
                    self.delegate.timeLapseBuilder(self, didFailWithError: error)
                }
            }
            
        } catch {
            print("\(error)")
        }
    }
    
    func dimensionsOfImage(url: URL) -> CGSize? {
        guard let imageData = try? Data(contentsOf: url),
              let image = UIImage(data: imageData)
        else {
            return nil
        }
        
        return image.size
    }
    
    func dimensionsOfImage(image: UIImage) -> CGSize? {
        return image.size
    }
    
    func appendPixelBufferForNSImage(_ image: NSImage, pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor, presentationTime: CMTime) -> Bool {
        var appendSucceeded = false
        
        autoreleasepool {
                let pixelBufferPool = pixelBufferAdaptor.pixelBufferPool!
            
                let pixelBufferPointer = UnsafeMutablePointer<CVPixelBuffer?>.allocate(capacity: 1)
                let status: CVReturn = CVPixelBufferPoolCreatePixelBuffer(
                    kCFAllocatorDefault,
                    pixelBufferPool,
                    pixelBufferPointer
                )
                
                if let pixelBuffer = pixelBufferPointer.pointee, status == 0 {
                    fillPixelBufferFromImage(image, pixelBuffer: pixelBuffer)
                    
                    appendSucceeded = pixelBufferAdaptor.append(
                        pixelBuffer,
                        withPresentationTime: presentationTime
                    )
                    
                    pixelBufferPointer.deinitialize(count: 1)
                } else {
                    NSLog("error: Failed to allocate pixel buffer from pool \(status)")
                }
                
                pixelBufferPointer.deallocate()
            
        }
        
        return appendSucceeded
    }
    
    func fillPixelBufferFromImage(_ image: UIImage, pixelBuffer: CVPixelBuffer) {
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))

        let ciimage = CIImage(cgImage: image.cgImage!)
        let rotatedImage = ciimage.oriented(.right)

        
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(
            data: pixelData,
            width: Int(image.size.height),
            height: Int(image.size.width),
            bitsPerComponent: 8,
            bytesPerRow: AudioSpectrogram.sampleCount * MemoryLayout<Float>.stride,
            space: rgbColorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
        )
        

        
        let cicontext = CIContext(cgContext: context!)
        cicontext.render(rotatedImage, to: pixelBuffer)

                
//        context?.clear(CGRect(x: 0, y: 0, width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer)))
//        context?.draw(image.cgImage!, in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
    }
}

#if os(macOS)
extension NSImage {
    var cgImage: CGImage? {
        var proposedRect = CGRect(origin: .zero, size: size)
        
        return cgImage(forProposedRect: &proposedRect,
                       context: nil,
                       hints: nil)
    }

}
#endif
