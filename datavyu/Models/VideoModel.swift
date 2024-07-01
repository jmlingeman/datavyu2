import AVFoundation
import SwiftUI

public class VideoModel: ObservableObject, Identifiable, Equatable, Hashable, Codable {
    @Published var videoFileURL: URL
    @Published var currentTime: Double
    @Published var currentPos: Double
    @Published var duration: Double
    @Published var markers: [Marker]
    @Published var selectedMarker: Marker?
    @Published var updates = 0
    @Published var filename: String
    @Published var isHidden = false

    @Published var fps: Float = 0

    var trackSettings: TrackSetting? = nil

    var isPrimaryVideo: Bool = false

    var player: AVPlayer

    /// The primary video will always have a sync point of 0
    /// Subsequent videos then sync to the time on the primary video
    @Published var syncOffset = 0.0
    @Published var syncMarker: Marker?

    var ready: Bool = false

    public static func == (lhs: VideoModel, rhs: VideoModel) -> Bool {
        if lhs.videoFileURL == rhs.videoFileURL {
            return true
        }
        return false
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(videoFileURL)
    }

    init(videoFilePath: URL) {
        videoFileURL = videoFilePath
        currentPos = 0.0
        currentTime = 0.0
        player = AVPlayer(url: videoFilePath)
        markers = []
        duration = 0.0

        filename = videoFilePath.lastPathComponent

        Task {
            try await populateMetadata()
        }
    }

    convenience init(videoFilePath: URL, trackSettings: TrackSetting) {
        self.init(videoFilePath: videoFilePath)
        self.trackSettings = trackSettings
    }

    func getFps() -> Float {
        fps
    }

    func populateMetadata() async throws {
        let asset = await player.currentItem?.asset

        if asset != nil {
            let tracks = try await asset!.loadTracks(withMediaType: .video)
            //                let tracks = asset!.tracks(withMediaType: .video)
            if tracks.count > 0 {
                let fpsPromise = try await tracks.first!.load(.nominalFrameRate) as Float
                let durTime = try await asset!.load(.duration) as CMTime

                DispatchQueue.main.async {
                    self.fps = fpsPromise
                    self.duration = durTime.seconds
                }
            }
        }
    }

    func copy() -> VideoModel {
        let newVideoModel = VideoModel(videoFilePath: videoFileURL)

        newVideoModel.duration = duration
        newVideoModel.player = player
        newVideoModel.currentTime = currentTime
        newVideoModel.trackSettings = trackSettings
        newVideoModel.currentPos = currentPos
        newVideoModel.selectedMarker = selectedMarker
        newVideoModel.markers = markers
        newVideoModel.ready = ready
        newVideoModel.syncMarker = syncMarker
        newVideoModel.syncOffset = syncOffset

        return newVideoModel
    }

    func play() {
        player.play()
    }

    func stop() {
        player.pause()
    }

    func getWindowTitle() -> String {
        "Video: \(filename)"
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
        markers.removeAll(where: { x in x.time == time })
    }

    func nextFrame() {
        player.currentItem!.step(byCount: 1)
        updateTimes()
    }

    func prevFrame() {
        player.currentItem!.step(byCount: -1)
        updateTimes()
    }

    func changeVolume(newVolume: Float) {
        player.volume = newVolume
    }

    func getVolume() -> Float {
        player.volume
    }

    func seek(to: Double, callback: (() -> Void)? = nil) {
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
                callback?()
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

    enum CodingKeys: CodingKey {
        case videoFileUrl
        case currentTime
        case currentPos
        case duration
        case markers
        case filename
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let fileUrl = try container.decode(URL.self, forKey: .videoFileUrl)
        videoFileURL = fileUrl
        currentTime = try container.decode(Double.self, forKey: .currentTime)
        currentPos = try container.decode(Double.self, forKey: .currentPos)
        duration = try container.decode(Double.self, forKey: .duration)
        markers = try container.decode([Marker].self, forKey: .currentTime)
        filename = try container.decode(String.self, forKey: .filename)
        player = AVPlayer(url: fileUrl)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(videoFileURL, forKey: .videoFileUrl)
        try container.encode(currentTime, forKey: .currentTime)
        try container.encode(currentPos, forKey: .currentPos)
        try container.encode(duration, forKey: .duration)
        try container.encode(markers, forKey: .markers)
    }
}

extension AVPlayer {
    func getCurrentTrackDuration() -> Float64 {
        guard let currentItem = currentItem else { return 0.0 }
        guard currentItem.loadedTimeRanges.count > 0 else { return 0.0 }

        let timeInSecond = CMTimeGetSeconds((currentItem.loadedTimeRanges[0].timeRangeValue).duration)

        return timeInSecond >= 0.0 ? timeInSecond : 0.0
    }
}
