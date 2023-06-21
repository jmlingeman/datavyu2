import SwiftUI
import AVFoundation

class VideoModel: ObservableObject, Identifiable, Equatable, Hashable {
    @Published var videoFilePath: String
    @Published var currentTime: Double
    @Published var currentPos: Double
    @Published var duration: Double
    @Published var markers: [Marker]

    let player: AVPlayer
    
    /// The primary video will always have a sync point of 0
    /// Subsequent videos then sync to the time on the primary video
    var syncOffset = 0.0

    static func == (lhs: VideoModel, rhs: VideoModel) -> Bool {
        if lhs.videoFilePath == rhs.videoFilePath {
            return true
        }
        return false
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(videoFilePath)
    }

    init(videoFilePath: String) {
        self.videoFilePath = videoFilePath
        currentPos = 0.0
        currentTime = 0.0
        player = AVPlayer(url: Bundle.main.url(forResource: videoFilePath, withExtension: "MOV")!)
        duration = player.getCurrentTrackDuration()
        markers = []
    }
    
    func play() {
        player.play()
    }
    
    func stop() {
        player.pause()
    }
    
    func getDuration() -> Double {
        if duration > 0 {
            return duration
        } else {
            duration = player.getCurrentTrackDuration()
            return duration
        }
    }
    
    func addMarker(time: Double) {
        markers.append(Marker(value: time))
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
        let time = CMTime(seconds: to, preferredTimescale: 600)
        player.currentItem!.seek(to: time, completionHandler: nil)
        updateTimes()
    }
    
    func seekPercentage(to: Double) {
        let relativeTime = to * getDuration()
        let time = CMTime(seconds: relativeTime, preferredTimescale: 600)
        player.currentItem!.seek(to: time, completionHandler: nil)
        print(to, relativeTime, getDuration(), time)
        updateTimes()
    }
    
    func updateTimes() {
        currentTime = player.currentTime().seconds
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
