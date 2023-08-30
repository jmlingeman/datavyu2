import SwiftUI
import AVFoundation

class VideoModel: ObservableObject, Identifiable, Equatable, Hashable {
    @Published var videoFileURL: URL
    @Published var currentTime: Double
    @Published var currentPos: Double
    @Published var duration: Double
    @Published var markers: [Marker]
    @Published var selectedMarker: Marker?
    @Published var updates = 0
    
    var trackSettings: TrackSetting? = nil

    var player: AVPlayer
    
    /// The primary video will always have a sync point of 0
    /// Subsequent videos then sync to the time on the primary video
    @Published var syncOffset = 0.0
    @Published var syncMarker: Marker?
    
    var ready: Bool = false

    static func == (lhs: VideoModel, rhs: VideoModel) -> Bool {
        if lhs.videoFileURL == rhs.videoFileURL {
            return true
        }
        return false
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(videoFileURL)
    }

    init(videoFilePath: URL) {
        self.videoFileURL = videoFilePath
        currentPos = 0.0
        currentTime = 0.0
        player = AVPlayer(url: videoFilePath)
        markers = []
        duration = 0.0
    }
    
    convenience init(videoFilePath: URL, trackSettings: TrackSetting) {
        self.init(videoFilePath: videoFilePath)
        self.trackSettings = trackSettings
    }
    
    
    func play() {
        player.play()
    }
    
    func stop() {
        player.pause()
    }
    
    func getDuration() -> Double {
        if duration == 0 {
            duration = player.getCurrentTrackDuration()
        }
        return duration
    }
    
    func getProportion(time: Double) -> Double {
        let val = time / getDuration()
        if val.isNaN {
            return 0
        } else {
            return val
        }
    }
    
    
    func addMarker(time: Double) {
        markers.append(Marker(value: time, videoDuration: getDuration()))
    }
    
    func deleteMarker(time: Double) {
        markers.removeAll(where: {x in x.time == time})
    }
    
    func nextFrame() {
        player.currentItem!.step(byCount: 1)
        updateTimes()
    }
    
    func prevFrame() {
        player.currentItem!.step(byCount: -1)
        updateTimes()
    }
    
    func seek(to: Double) {
        let jumpTime: Double
        if to + syncOffset > getDuration() {
            jumpTime = getDuration()
        } else {
            jumpTime = to + syncOffset
        }
        let time = CMTime(seconds: jumpTime, preferredTimescale: 600)
        player.currentItem!.seek(to: time, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero) { finished in
            if finished {
                self.updateTimes()
            }
        }
    }
    
    func seekPercentage(to: Double) {
        var relativeTime = to * getDuration() + syncOffset
        if relativeTime > getDuration() {
            relativeTime = getDuration()
        }
        let time = CMTime(seconds: relativeTime, preferredTimescale: 600)
        player.currentItem!.seek(to: time, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero) { finished in
            if finished {
                self.updateTimes()
            }
        }
    }
    
    func updateTimes() {
        currentTime = player.currentTime().seconds + syncOffset
        currentPos = currentTime / getDuration()
    }
}

extension AVPlayer {
    func getCurrentTrackDuration () -> Float64 {
        guard let currentItem = self.currentItem else { return 0.0 }
        guard currentItem.loadedTimeRanges.count > 0 else { return 0.0 }
        
        let timeInSecond = CMTimeGetSeconds((currentItem.loadedTimeRanges[0].timeRangeValue).duration);
        
        return timeInSecond >= 0.0 ? timeInSecond : 0.0
    }
}
