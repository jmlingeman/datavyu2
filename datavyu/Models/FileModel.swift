//
//  FileModel.swift
//  datavyu
//
//  Created by Jesse Lingeman on 6/19/23.
//

import Foundation
import SwiftUI

class FileModel: ObservableObject, Identifiable {
    var version = "#4"
    
    @Published var videoModels: [VideoModel]
    @Published var sheetModel: SheetModel
    @Published var updates: Int
    @Published var primaryMarker : Marker?
    @Published var primaryVideo : VideoModel?
    @Published var longestDuration : Double = 0
    
    var videoObservers: [NSKeyValueObservation] = []
    
    var currentShuttleSpeedIdx: Int
    var legacyProjectSettings: ProjectFile?
    
    let config = Config()

    init() {
        self.sheetModel = SheetModel(sheetName: "default")
        self.videoModels = []
        self.updates = 0
        currentShuttleSpeedIdx = config.shuttleSpeeds.firstIndex(of: 0)!
    }
    
    init(sheetModel: SheetModel) {
        self.sheetModel = sheetModel
        self.videoModels = []
        self.updates = 0
        currentShuttleSpeedIdx = config.shuttleSpeeds.firstIndex(of: 0)!
    }
    
    init(sheetModel: SheetModel, videoModels: [VideoModel]) {
        self.sheetModel = sheetModel
        self.videoModels = videoModels
        self.updates = 0
        currentShuttleSpeedIdx = config.shuttleSpeeds.firstIndex(of: 0)!
        
        if videoModels.count > 0 {
            self.primaryVideo = videoModels[0]
        }
        
        for videoModel in videoModels {
            var observer = videoModel.player.currentItem!.observe(\.status, options:  [.new, .old], changeHandler: { (playerItem, change) in
                if playerItem.status == .readyToPlay {
                    videoModel.ready = true
                    videoModel.duration = videoModel.player.getCurrentTrackDuration()
                    
                    if videoModel.duration > self.longestDuration {
                        self.longestDuration = videoModel.duration
                        self.primaryVideo = videoModel
                    }
                }
            })
            videoObservers.append(observer)
        }
    }
    
    convenience init(sheetModel: SheetModel, videoModels: [VideoModel], legacyProjectSettings: ProjectFile) {
        self.init(sheetModel: sheetModel, videoModels: videoModels)
        self.legacyProjectSettings = legacyProjectSettings
    }
    
    func changeShuttleSpeed(step: Int) {
        if currentShuttleSpeedIdx + step < config.shuttleSpeeds.count && currentShuttleSpeedIdx + step >= 0 {
            currentShuttleSpeedIdx += step
        }
        for video in videoModels {
            video.player.rate = config.shuttleSpeeds[currentShuttleSpeedIdx]
        }
    }
    
    func removeVideoModel(videoModel: VideoModel) {
        let idx = videoModels.firstIndex(of: videoModel)
        if idx != nil {
            videoModels.remove(at: idx!)
        }
        if videoModels.count > 0 {
            primaryVideo = videoModels[0]
        }
    }
    
    func resetShuttleSpeed() {
        currentShuttleSpeedIdx = config.shuttleSpeeds.firstIndex(of: 0)!
    }
    
    func addVideo(videoUrl: URL) {
        let vm = VideoModel(videoFilePath: videoUrl)
        print(videoUrl.absoluteString)
        self.addVideo(videoModel: vm)
    }
    
    func addVideo(videoModel: VideoModel) {
        self.videoModels.append(videoModel)
        
        if videoModels.count == 1 {
            primaryVideo = videoModels[0]
        }
        
        if videoModel.duration > longestDuration {
            longestDuration = videoModel.duration
            self.primaryVideo = videoModel
        }
    }
    
    func seekAllVideos(to: Double) {
        for videoModel in videoModels {
            videoModel.seek(to: to)
        }
    }
    
    func seekAllVideosPercent(to: Double) {
        for videoModel in videoModels {
            videoModel.seekPercentage(to: to)
        }
    }
    
    func currentTime() -> Double {
        if videoModels.count >= 1 {
            return primaryVideo!.currentTime
        } else {
            return 0.0
        }
    }
    
    func syncVideos() {
        let priTime = currentTime()
        for videoModel in videoModels {
            videoModel.seek(to: priTime)
        }
    }
}

struct CurrentTimeEnvironmentKey: EnvironmentKey {
    static var defaultValue = 0.0
}

extension EnvironmentValues {
    var currentTime: Double {
        get { self[CurrentTimeEnvironmentKey.self] }
        set { self[CurrentTimeEnvironmentKey.self] = newValue }
    }
}
