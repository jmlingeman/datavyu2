import Foundation
import CoreMedia

class CMSampleBufferFactory
{
    var asbd: AudioStreamBasicDescription?
    
    func setASBD(asbd: AudioStreamBasicDescription) {
        self.asbd = asbd
    }
    
    func createSilentAudio(presentationTime: CMTime, nFrames: Int, numChannels: UInt32) -> CMSampleBuffer? {
        let bytesPerFrame = UInt32(2 * numChannels)
        let blockSize = nFrames*Int(bytesPerFrame)
        
        var block: CMBlockBuffer?
        var status = CMBlockBufferCreateWithMemoryBlock(
            allocator: kCFAllocatorDefault,
            memoryBlock: nil,
            blockLength: blockSize,
            blockAllocator: nil,
            customBlockSource: nil,
            offsetToData: 0,
            dataLength: blockSize,
            flags: 0,
            blockBufferOut: &block
        )
        assert(status == kCMBlockBufferNoErr)
        
        guard var eBlock = block else { return nil }
        
        // we seem to get zeros from the above, but I can't find it documented. so... memset:
        status = CMBlockBufferFillDataBytes(with: 0, blockBuffer: eBlock, offsetIntoDestination: 0, dataLength: blockSize)
        assert(status == kCMBlockBufferNoErr)
        
        
        var formatDesc: CMAudioFormatDescription?
        status = CMAudioFormatDescriptionCreate(allocator: kCFAllocatorDefault, asbd: &(asbd)!, layoutSize: 0, layout: nil, magicCookieSize: 0, magicCookie: nil, extensions: nil, formatDescriptionOut: &formatDesc)
        assert(status == noErr)
        
        var sampleBuffer: CMSampleBuffer?
        
        status = CMAudioSampleBufferCreateReadyWithPacketDescriptions(
            allocator: kCFAllocatorDefault,
            dataBuffer: eBlock,
            formatDescription: formatDesc!,
            sampleCount: nFrames,
            presentationTimeStamp: presentationTime,
            packetDescriptions: nil,
            sampleBufferOut: &sampleBuffer
        )
        assert(status == noErr)
        return sampleBuffer
    }
}
