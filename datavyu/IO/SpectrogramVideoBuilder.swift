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
        didMakeProgress = progress
        didFinish = finished
        didFailWithError = failed
    }

    func timeLapseBuilder(_: SpectrogramVideoBuilder, didMakeProgress progress: Progress) {
        didMakeProgress?(progress)
    }

    func timeLapseBuilder(_: SpectrogramVideoBuilder, didFinishWithURL url: URL) {
        didFinish?(url)
    }

    func timeLapseBuilder(_: SpectrogramVideoBuilder, didFailWithError error: Error) {
        didFailWithError?(error)
    }
}

public class SpectrogramVideoBuilder: ObservableObject {
    @Published var progress = 0.0
    @Published var isFinished = false

    // Number of frames before the spectrogram reeaches the center line
    // We will ditch this many frames so that the audio that is playing is centered
    let framesToCenterLine = 23

    public var delegate: SpectrogramVideoBuilderDelegate

    var videoWriter: AVAssetWriter?

    var outputCanvasSize: CGSize?

    public init(delegate: SpectrogramVideoBuilderDelegate?) {
        if delegate == nil {
            self.delegate = SpectrogramDelegate { _ in

            } finished: { _ in

            } failed: { error in
                print(error)
            }
        } else {
            self.delegate = delegate!
        }
    }

    public func processSample(sample _: CMSampleBuffer) {}

    public func build(with player: AVPlayer, type: AVFileType, toOutputPath: URL) {
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
                    AVLinearPCMIsNonInterleaved: false,
                ]
                let assetReaderAudioOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: audioSettings)

                if assetReader.canAdd(assetReaderAudioOutput) {
                    assetReader.add(assetReaderAudioOutput)
                } else {
                    fatalError("could not add audio output reader")
                }

                let canvasSize = AudioSpectrogram.canvasSize
                // The output will be rotate 90 degrees
                outputCanvasSize = CGSize(width: canvasSize.height, height: canvasSize.width)

                var error: NSError?
                let videoOutputURL = toOutputPath

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
                        AVVideoWidthKey: outputCanvasSize!.width as AnyObject,
                        AVVideoHeightKey: outputCanvasSize!.height as AnyObject,
                        AVVideoCompressionPropertiesKey: [
                            AVVideoExpectedSourceFrameRateKey: 60 as AnyObject,
                            //          AVVideoAverageBitRateKey : NSInteger(1000000),
                            //          AVVideoMaxKeyFrameIntervalKey : NSInteger(16),
                            //          AVVideoProfileLevelKey : AVVideoProfileLevelH264BaselineAutoLevel
                        ] as AnyObject,
                    ]

                    let videoWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoSettings)

                    let sourceBufferAttributes = [
                        kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32ARGB),
                        kCVPixelBufferWidthKey as String: Float(outputCanvasSize!.width),
                        kCVPixelBufferHeightKey as String: Float(outputCanvasSize!.height),
                        kCVPixelBufferCGImageCompatibilityKey as String: true,
                        kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
                    ] as [String: Any]

                    let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(
                        assetWriterInput: videoWriterInput,
                        sourcePixelBufferAttributes: sourceBufferAttributes
                    )

                    assert(videoWriter.canAdd(videoWriterInput))
                    videoWriter.add(videoWriterInput)

                    var frameCount: Int64 = 0

                    let silentSampleGenerator = CMSampleBufferFactory()

                    if assetReader.startReading(), videoWriter.startWriting() {
                        videoWriter.startSession(atSourceTime: CMTime.zero)
                        assert(pixelBufferAdaptor.pixelBufferPool != nil)

                        let media_queue = DispatchQueue(label: "mediaInputQueue")
                        var offsetPresentationTime: CMTime?
                        var prevPresentationTime: CMTime?
                        var oneFramePresentationTimeDiff: CMTime?
                        var prevSample: CMSampleBuffer?

                        videoWriterInput.requestMediaDataWhenReady(on: media_queue) {
                            while videoWriterInput.isReadyForMoreMediaData {
//                                let presentationTime = CMTimeMake(value: frameCount, timescale: framesPerSecond)

                                let sample = assetReaderAudioOutput.copyNextSampleBuffer()

                                /*
                                 TODO: Don't write the first 23 images until
                                 we get to a presentation timestamp at the centerline,
                                 then start writing the video and subtract off that time
                                 */

                                if sample != nil {
                                    if silentSampleGenerator.asbd == nil {
                                        silentSampleGenerator.setASBD(asbd: CMSampleBufferGetFormatDescription(sample!)!.audioStreamBasicDescription!)
                                    }
                                    let presentationTime = CMSampleBufferGetPresentationTimeStamp(sample!)
                                    let image = spectrogram.processBuffer(sampleBuffer: sample!)
                                    let nsImage = spectrogramController.formatImage(image: image!)
                                    if frameCount == self.framesToCenterLine {
                                        offsetPresentationTime = presentationTime
                                    }
                                    if frameCount >= self.framesToCenterLine {
                                        let centeredPresentationTime = presentationTime - offsetPresentationTime!
                                        if !self.appendPixelBufferForNSImage(nsImage, pixelBufferAdaptor: pixelBufferAdaptor, presentationTime: centeredPresentationTime) {
                                            error = NSError(
                                                domain: kErrorDomain,
                                                code: kFailedToAppendPixelBufferError,
                                                userInfo: ["description": "AVAssetWriterInputPixelBufferAdapter failed to append pixel buffer"]
                                            )

                                            break
                                        }
                                    }

                                    DispatchQueue.main.async {
                                        self.progress = presentationTime.seconds / totalTime
                                    }

                                    frameCount += 1
                                    if prevPresentationTime != nil {
                                        oneFramePresentationTimeDiff = presentationTime - prevPresentationTime!
                                    }
                                    prevPresentationTime = presentationTime
                                    prevSample = sample

                                } else {
                                    for _ in 0 ... self.framesToCenterLine {
                                        let presentationTime = prevPresentationTime! + oneFramePresentationTimeDiff!
                                        CMBlockBufferFillDataBytes(with: 0, blockBuffer: prevSample!.dataBuffer!, offsetIntoDestination: 0, dataLength: prevSample!.dataBuffer!.dataLength)
                                        let image = spectrogram.processBuffer(sampleBuffer: prevSample!)
                                        let nsImage = spectrogramController.formatImage(image: image!)
                                        if frameCount >= self.framesToCenterLine {
                                            if !self.appendPixelBufferForNSImage(nsImage, pixelBufferAdaptor: pixelBufferAdaptor, presentationTime: presentationTime) {
                                                error = NSError(
                                                    domain: kErrorDomain,
                                                    code: kFailedToAppendPixelBufferError,
                                                    userInfo: ["description": "AVAssetWriterInputPixelBufferAdapter failed to append pixel buffer"]
                                                )

                                                break
                                            }
                                        }

                                        DispatchQueue.main.async {
                                            self.progress = presentationTime.seconds / totalTime
                                        }

                                        prevPresentationTime = presentationTime
                                        frameCount += 1
                                    }
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
                                    DispatchQueue.main.async {
                                        self.isFinished = true
                                    }
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
                    delegate.timeLapseBuilder(self, didFailWithError: error)
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
        image.size
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

        let resizedImage = image.resized(to: NSSize(width: outputCanvasSize!.width, height: outputCanvasSize!.height))!
        resizedImage.drawHorizontalCenterLine()

        let ciimage = CIImage(cgImage: resizedImage.cgImage!)
        let rotatedImage = ciimage.oriented(.rightMirrored)

        let resizeFilter = CIFilter(name: "CILanczosScaleTransform")!

        // Desired output size
        let targetSize = NSSize(width: outputCanvasSize!.width, height: outputCanvasSize!.height)

        // Compute scale and corrective aspect ratio
        let scale = targetSize.height / rotatedImage.extent.height
        let aspectRatio = targetSize.width / (rotatedImage.extent.width * scale)

        // Apply resizing
        resizeFilter.setValue(rotatedImage, forKey: kCIInputImageKey)
        resizeFilter.setValue(scale, forKey: kCIInputScaleKey)
        resizeFilter.setValue(aspectRatio, forKey: kCIInputAspectRatioKey)

        let outputImage = resizeFilter.outputImage!

        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(
            data: pixelData,
            width: Int(outputCanvasSize!.width),
            height: Int(outputCanvasSize!.height),
            bitsPerComponent: 8,
            bytesPerRow: AudioSpectrogram.sampleCount * MemoryLayout<Int32>.stride,
            space: rgbColorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
        )

        let cicontext = CIContext(cgContext: context!)
//        cicontext.render(rotatedImage, to: pixelBuffer)

        cicontext.render(outputImage, to: pixelBuffer, bounds: ciimage.extent, colorSpace: rgbColorSpace)

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

        // Draw a line down the center so we know where to sync it
        func drawHorizontalCenterLine() {
            lockFocus()
            let path = NSBezierPath()
            path.lineWidth = 4
            path.move(to: NSPoint(x: 0, y: size.height / 2))
            path.line(to: NSPoint(x: size.width, y: size.height / 2))
            NSColor.red.setStroke()
            path.stroke()
            unlockFocus()
        }

        func resized(to newSize: NSSize) -> NSImage? {
            if let bitmapRep = NSBitmapImageRep(
                bitmapDataPlanes: nil, pixelsWide: Int(newSize.width), pixelsHigh: Int(newSize.height),
                bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                colorSpaceName: .calibratedRGB, bytesPerRow: 0, bitsPerPixel: 0
            ) {
                bitmapRep.size = newSize
                NSGraphicsContext.saveGraphicsState()
                NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmapRep)
                draw(in: NSRect(x: 0, y: 0, width: newSize.width, height: newSize.height), from: .zero, operation: .copy, fraction: 1.0)
                NSGraphicsContext.restoreGraphicsState()

                let resizedImage = NSImage(size: newSize)
                resizedImage.addRepresentation(bitmapRep)
                return resizedImage
            }

            return nil
        }
    }
#endif
