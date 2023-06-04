import SwiftUI

class VideoModel: ObservableObject, Identifiable, Equatable, Hashable {
    @Published var videoFilePath: String
    @Published var currentTime: Double
    @Published var currentPos: Double
    @Published var duration: Double
    
    static func == (lhs: VideoModel, rhs: VideoModel) -> Bool {
        if(lhs.videoFilePath == rhs.videoFilePath) {
            return true
        }
        return false
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(videoFilePath)
    }
    
    init(videoFilePath: String) {
        self.videoFilePath = videoFilePath
        self.currentPos = 0.0
        self.currentTime = 0.0
        self.duration = 0.0
    }
}
