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

    
    init(sheetModel: SheetModel) {
        self.sheetModel = sheetModel
        self.videoModels = []
        self.updates = 0
    }
    
    init(sheetModel: SheetModel, videoModels: [VideoModel]) {
        self.sheetModel = sheetModel
        self.videoModels = videoModels
        self.updates = 0
        
        if videoModels.count > 0 {
            primaryVideo = videoModels[0]
        }
    }
    
    func addVideo(videoModel: VideoModel) {
        self.videoModels.append(videoModel)
        
        if videoModels.count > 0 {
            primaryVideo = videoModels[0]
        }
    }
    
    func longestDuration() -> Double {
        return videoModels.map({x in x.getDuration() + x.syncOffset}).max() ?? 0
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
            return videoModels[0].currentTime
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
