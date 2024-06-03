/*
 See the LICENSE.txt file for this sample’s licensing information.

 Abstract:
 The class that provides a signal that represents a drum loop.
 */

import Accelerate
import AVFoundation
import Combine

class AudioSpectrogram: NSObject, ObservableObject {
    /// An enumeration that specifies the drum loop provider's mode.
    enum Mode: String, CaseIterable, Identifiable {
        case linear
        case mel

        var id: Self { self }
    }

    @Published var mode = Mode.mel

    @Published var gain: Double = 0.025
    @Published var zeroReference: Double = 1000

    @Published var outputImage = AudioSpectrogram.emptyCGImage

    // MARK: Initialization

    override init() {
        super.init()

//        configureMicrophoneCaptureSession()
//        audioOutput.setSampleBufferDelegate(self,
//                                            queue: captureQueue)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Properties

    lazy var melSpectrogram = MelSpectrogram(sampleCount: AudioSpectrogram.sampleCount)

    /// The number of samples per frame — the height of the spectrogram.
    static let sampleCount = 1024

    /// The number of displayed buffers — the width of the spectrogram.
    static let bufferCount = 768

    /// Determines the overlap between frames.
    static let hopCount = 512

    static let canvasSize: CGSize = CGSizeMake(CGFloat(bufferCount), CGFloat(sampleCount))

    let captureSession = AVCaptureSession()
    let audioOutput = AVCaptureAudioDataOutput()
    let captureQueue = DispatchQueue(label: "captureQueue",
                                     qos: .userInitiated,
                                     attributes: [],
                                     autoreleaseFrequency: .workItem)
    let sessionQueue = DispatchQueue(label: "sessionQueue",
                                     attributes: [],
                                     autoreleaseFrequency: .workItem)

    let forwardDCT = vDSP.DCT(count: sampleCount,
                              transformType: .II)!

    /// The window sequence for reducing spectral leakage.
    let hanningWindow = vDSP.window(ofType: Float.self,
                                    usingSequence: .hanningDenormalized,
                                    count: sampleCount,
                                    isHalfWindow: false)

    let dispatchSemaphore = DispatchSemaphore(value: 1)

    /// The highest frequency that the app can represent.
    ///
    /// The first call of `AudioSpectrogram.captureOutput(_:didOutput:from:)` calculates
    /// this value.
    var nyquistFrequency: Float?

    /// A buffer that contains the raw audio data from AVFoundation.
    var rawAudioData = [Int16]()

    /// Raw frequency-domain values.
    var frequencyDomainValues = [Float](repeating: 0,
                                        count: bufferCount * sampleCount)

    static var rgbImageFormat = vImage_CGImageFormat(
        bitsPerComponent: 32,
        bitsPerPixel: 32 * 3,
        colorSpace: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGBitmapInfo(
            rawValue: kCGBitmapByteOrder32Host.rawValue |
                CGBitmapInfo.floatComponents.rawValue |
                CGImageAlphaInfo.none.rawValue)
    )!

    static var outputImageFormat = vImage_CGImageFormat(
        bitsPerComponent: 8,
        bitsPerPixel: 8 * 4,
        colorSpace: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGBitmapInfo(
            rawValue:
            CGImageAlphaInfo.noneSkipLast.rawValue)
    )!

    /// RGB vImage buffer that contains a vertical representation of the audio spectrogram.

    let redBuffer = vImage.PixelBuffer<vImage.PlanarF>(
        width: AudioSpectrogram.sampleCount,
        height: AudioSpectrogram.bufferCount
    )

    let greenBuffer = vImage.PixelBuffer<vImage.PlanarF>(
        width: AudioSpectrogram.sampleCount,
        height: AudioSpectrogram.bufferCount
    )

    let blueBuffer = vImage.PixelBuffer<vImage.PlanarF>(
        width: AudioSpectrogram.sampleCount,
        height: AudioSpectrogram.bufferCount
    )

    let rgbImageBuffer = vImage.PixelBuffer<vImage.InterleavedFx3>(
        width: AudioSpectrogram.sampleCount,
        height: AudioSpectrogram.bufferCount
    )

    /// A reusable array that contains the current frame of time-domain audio data as single-precision
    /// values.
    var timeDomainBuffer = [Float](repeating: 0,
                                   count: sampleCount)

    /// A resuable array that contains the frequency-domain representation of the current frame of
    /// audio data.
    var frequencyDomainBuffer = [Float](repeating: 0,
                                        count: sampleCount)

    // MARK: Instance Methods

    /// Process a frame of raw audio data.
    ///
    /// * Convert supplied `Int16` values to single-precision and write the result to `timeDomainBuffer`.
    /// * Apply a Hann window to the audio data in `timeDomainBuffer`.
    /// * Perform a forward discrete cosine transform and write the result to `frequencyDomainBuffer`.
    /// * Convert frequency-domain values in `frequencyDomainBuffer` to decibels and scale by the
    ///     `gain` value.
    /// * Append the values in `frequencyDomainBuffer` to `frequencyDomainValues`.
    func processData(values: [Int16]) {
        vDSP.convertElements(of: values,
                             to: &timeDomainBuffer)

        vDSP.multiply(timeDomainBuffer,
                      hanningWindow,
                      result: &timeDomainBuffer)

        forwardDCT.transform(timeDomainBuffer,
                             result: &frequencyDomainBuffer)

        vDSP.absolute(frequencyDomainBuffer,
                      result: &frequencyDomainBuffer)

        switch mode {
        case .linear:
            vDSP.convert(amplitude: frequencyDomainBuffer,
                         toDecibels: &frequencyDomainBuffer,
                         zeroReference: Float(zeroReference))
        case .mel:
            melSpectrogram.computeMelSpectrogram(
                values: &frequencyDomainBuffer)

            vDSP.convert(power: frequencyDomainBuffer,
                         toDecibels: &frequencyDomainBuffer,
                         zeroReference: Float(zeroReference))
        }

        vDSP.multiply(Float(gain),
                      frequencyDomainBuffer,
                      result: &frequencyDomainBuffer)

        if frequencyDomainValues.count > AudioSpectrogram.sampleCount {
            frequencyDomainValues.removeFirst(AudioSpectrogram.sampleCount)
        }

        frequencyDomainValues.append(contentsOf: frequencyDomainBuffer)
    }

    /// Creates an audio spectrogram `CGImage` from `frequencyDomainValues`.
    func makeAudioSpectrogramImage() -> CGImage {
        frequencyDomainValues.withUnsafeMutableBufferPointer {
            let planarImageBuffer = vImage.PixelBuffer(
                data: $0.baseAddress!,
                width: AudioSpectrogram.sampleCount,
                height: AudioSpectrogram.bufferCount,
                byteCountPerRow: AudioSpectrogram.sampleCount * MemoryLayout<Float>.stride,
                pixelFormat: vImage.PlanarF.self
            )

            AudioSpectrogram.multidimensionalLookupTable.apply(
                sources: [planarImageBuffer],
                destinations: [redBuffer, greenBuffer, blueBuffer],
                interpolation: .half
            )

            rgbImageBuffer.interleave(
                planarSourceBuffers: [redBuffer, greenBuffer, blueBuffer])
        }

        let image = rgbImageBuffer.makeCGImage(cgImageFormat: AudioSpectrogram.rgbImageFormat)

        return image ?? AudioSpectrogram.emptyCGImage
    }

    static func configureSampleBuffer(pcmBuffer: AVAudioPCMBuffer) -> CMSampleBuffer? {
        let audioBufferList = pcmBuffer.mutableAudioBufferList
        let asbd = pcmBuffer.format.streamDescription

        var sampleBuffer: CMSampleBuffer? = nil
        var format: CMFormatDescription? = nil

        var status = CMAudioFormatDescriptionCreate(allocator: kCFAllocatorDefault,
                                                    asbd: asbd,
                                                    layoutSize: 0,
                                                    layout: nil,
                                                    magicCookieSize: 0,
                                                    magicCookie: nil,
                                                    extensions: nil,
                                                    formatDescriptionOut: &format)
        if status != noErr { return nil }

        var timing = CMSampleTimingInfo(duration: CMTime(value: 1, timescale: Int32(asbd.pointee.mSampleRate)),
                                        presentationTimeStamp: CMClockGetTime(CMClockGetHostTimeClock()),
                                        decodeTimeStamp: CMTime.invalid)
        status = CMSampleBufferCreate(allocator: kCFAllocatorDefault,
                                      dataBuffer: nil,
                                      dataReady: false,
                                      makeDataReadyCallback: nil,
                                      refcon: nil,
                                      formatDescription: format,
                                      sampleCount: CMItemCount(pcmBuffer.frameLength),
                                      sampleTimingEntryCount: 1,
                                      sampleTimingArray: &timing,
                                      sampleSizeEntryCount: 0,
                                      sampleSizeArray: nil,
                                      sampleBufferOut: &sampleBuffer)
        if status != noErr { NSLog("CMSampleBufferCreate returned error: \(status)"); return nil }

        status = CMSampleBufferSetDataBufferFromAudioBufferList(sampleBuffer!,
                                                                blockBufferAllocator: kCFAllocatorDefault,
                                                                blockBufferMemoryAllocator: kCFAllocatorDefault,
                                                                flags: kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment,
                                                                bufferList: audioBufferList)
        if status != noErr { NSLog("CMSampleBufferSetDataBufferFromAudioBufferList returned error: \(status)"); return nil }

        return sampleBuffer
    }

    var converter: AVAudioConverter? = nil
    var convertBuffer: AVAudioPCMBuffer? = nil

    public func convertPCMToPCMInt16(buffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer? {
        // https://stackoverflow.com/questions/42660859/avaudioconverter-float32-48khz-int16-16khz-conversion-failure
        let targetFormat = AVAudioFormat(commonFormat: AVAudioCommonFormat.pcmFormatInt16, sampleRate: 44100, channels: 1, interleaved: false)

        if converter == nil {
            convertBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat!, frameCapacity: buffer.frameCapacity)
            convertBuffer?.frameLength = convertBuffer!.frameCapacity
            converter = AVAudioConverter(from: buffer.format, to: convertBuffer!.format)
            converter?.sampleRateConverterAlgorithm = AVSampleRateConverterAlgorithm_Normal
            converter?.sampleRateConverterQuality = .max

            print(buffer.format)
            print(convertBuffer!.format)
        }

        guard let convertBuffer = convertBuffer else { return nil }

        print("Converter: \(converter!)")
        print("Converter buffer: \(self.convertBuffer!)")
        print("Converter buffer format: \(self.convertBuffer!.format)")
        print("Source buffer: \(buffer)")
        print("Source buffer format: \(buffer.format)")

        let inputBlock: AVAudioConverterInputBlock = { _, outStatus in
            outStatus.pointee = AVAudioConverterInputStatus.haveData
            return buffer
        }

        var error: NSError? = nil
        let status: AVAudioConverterOutputStatus = converter!.convert(to: convertBuffer, error: &error, withInputFrom: inputBlock)
        // TODO: check status
        print("CONVERSION STATUS: \(status)")

        return convertBuffer
    }

    public func processBuffer(sampleBuffer: CMSampleBuffer) -> CGImage? {
        var asbd = CMSampleBufferGetFormatDescription(sampleBuffer)!.audioStreamBasicDescription!
        var audioBufferList = AudioBufferList()
        var blockBuffer: CMBlockBuffer?

        let error = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(
            sampleBuffer,
            bufferListSizeNeededOut: nil,
            bufferListOut: &audioBufferList,
            bufferListSize: MemoryLayout<AudioBufferList>.size,
            blockBufferAllocator: nil,
            blockBufferMemoryAllocator: nil,
            flags: kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment,
            blockBufferOut: &blockBuffer
        )

        return processBuffer(sampleBuffer: sampleBuffer, audioBufferList: audioBufferList)
    }

    public func processBuffer(sampleBuffer: CMSampleBuffer, audioBufferList: AudioBufferList) -> CGImage? {
        guard let data = audioBufferList.mBuffers.mData else {
            print("No buffer data")
            return nil
        }

        /// The _Nyquist frequency_ is the highest frequency that a sampled system can properly
        /// reproduce and is half the sampling rate of such a system. Although  this app doesn't use
        /// `nyquistFrequency`,  you may find this code useful to add an overlay to the user interface.
        if nyquistFrequency == nil {
            let duration = Float(CMSampleBufferGetDuration(sampleBuffer).value)
            let timescale = Float(CMSampleBufferGetDuration(sampleBuffer).timescale)
            let numsamples = Float(CMSampleBufferGetNumSamples(sampleBuffer))
            nyquistFrequency = 0.5 / (duration / timescale / numsamples)
        }

        /// Because the audio spectrogram code requires exactly `sampleCount` (which the app defines
        /// as 1024) samples, but audio sample buffers from AVFoundation may not always contain exactly
        /// 1024 samples, the app adds the contents of each audio sample buffer to `rawAudioData`.
        ///
        /// The following code creates an array from `data` and appends it to  `rawAudioData`:
        if rawAudioData.count < AudioSpectrogram.sampleCount * 2 {
            let actualSampleCount = CMSampleBufferGetNumSamples(sampleBuffer)

            let pointer = data.bindMemory(to: Int16.self,
                                          capacity: actualSampleCount)
            let buffer = UnsafeBufferPointer(start: pointer,
                                             count: actualSampleCount)

            rawAudioData.append(contentsOf: Array(buffer))
        }

        /// The following code app passes the first `sampleCount`elements of raw audio data to the
        /// `processData(values:)` function, and removes the first `hopCount` elements from
        /// `rawAudioData`.
        ///
        /// By removing fewer elements than each step processes, the rendered frames of data overlap,
        /// ensuring no loss of audio data.
        while rawAudioData.count >= AudioSpectrogram.sampleCount {
            let dataToProcess = Array(rawAudioData[0 ..< AudioSpectrogram.sampleCount])
            rawAudioData.removeFirst(AudioSpectrogram.hopCount)
            processData(values: dataToProcess)
        }

        let outputImage = makeAudioSpectrogramImage()
        self.outputImage = outputImage

        return outputImage
    }

    public func processBuffer(pcmBuffer: AVAudioPCMBuffer) -> CGImage? {
        let pcmBufferInt16 = convertPCMToPCMInt16(buffer: pcmBuffer)
        let sampleBuffer = AudioSpectrogram.configureSampleBuffer(pcmBuffer: pcmBufferInt16!)!

        let audioBufferList = pcmBufferInt16!.mutableAudioBufferList

        var blockBuffer: CMBlockBuffer?

        let v = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(
            sampleBuffer,
            bufferListSizeNeededOut: nil,
            bufferListOut: audioBufferList,
            bufferListSize: MemoryLayout.stride(ofValue: audioBufferList),
            blockBufferAllocator: nil,
            blockBufferMemoryAllocator: nil,
            flags: kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment,
            blockBufferOut: &blockBuffer
        )
        let error = NSError(domain: NSOSStatusErrorDomain, code: Int(v), userInfo: nil)
        print("AudioBufferList: \(v) \(error)")

        return processBuffer(sampleBuffer: sampleBuffer, audioBufferList: audioBufferList.pointee)
    }
}

import Cocoa

// MARK: Utility functions

extension AudioSpectrogram {
    /// Returns the RGB values from a blue -> red -> green color map for a specified value.
    ///
    /// Values near zero return dark blue, `0.5` returns red, and `1.0` returns full-brightness green.
    static var multidimensionalLookupTable: vImage.MultidimensionalLookupTable = {
        let entriesPerChannel = UInt8(32)
        let srcChannelCount = 1
        let destChannelCount = 3

        let lookupTableElementCount = Int(pow(Float(entriesPerChannel),
                                              Float(srcChannelCount))) *
            Int(destChannelCount)

        let tableData = [UInt16](unsafeUninitializedCapacity: lookupTableElementCount) {
            buffer, count in

            /// Supply the samples in the range `0...65535`. The transform function
            /// interpolates these to the range `0...1`.
            let multiplier = CGFloat(UInt16.max)
            var bufferIndex = 0

            for gray in 0 ..< entriesPerChannel {
                /// Create normalized red, green, and blue values in the range `0...1`.
                let normalizedValue = CGFloat(gray) / CGFloat(entriesPerChannel - 1)

                // Define `hue` that's blue at `0.0` to red at `1.0`.
                let hue = 0.6666 - (0.6666 * normalizedValue)
                let brightness = sqrt(normalizedValue)

                let color = NSColor(hue: hue,
                                    saturation: 1,
                                    brightness: brightness,
                                    alpha: 1)

                var red = CGFloat()
                var green = CGFloat()
                var blue = CGFloat()

                color.getRed(&red,
                             green: &green,
                             blue: &blue,
                             alpha: nil)

                buffer[bufferIndex] = UInt16(green * multiplier)
                bufferIndex += 1
                buffer[bufferIndex] = UInt16(red * multiplier)
                bufferIndex += 1
                buffer[bufferIndex] = UInt16(blue * multiplier)
                bufferIndex += 1
            }

            count = lookupTableElementCount
        }

        let entryCountPerSourceChannel = [UInt8](repeating: entriesPerChannel,
                                                 count: srcChannelCount)

        return vImage.MultidimensionalLookupTable(entryCountPerSourceChannel: entryCountPerSourceChannel,
                                                  destinationChannelCount: destChannelCount,
                                                  data: tableData)
    }()

    /// A 1x1 Core Graphics image.
    static var emptyCGImage: CGImage = {
        let buffer = vImage.PixelBuffer(
            pixelValues: [0],
            size: .init(width: 1, height: 1),
            pixelFormat: vImage.Planar8.self
        )

        let fmt = vImage_CGImageFormat(
            bitsPerComponent: 8,
            bitsPerPixel: 8,
            colorSpace: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
            renderingIntent: .defaultIntent
        )

        return buffer.makeCGImage(cgImageFormat: fmt!)!
    }()
}
