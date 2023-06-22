//
//  FileModel.swift
//  datavyu
//
//  Created by Jesse Lingeman on 6/19/23.
//

import Foundation
class FileModel: ObservableObject, Identifiable {
    @Published var videoModels: [VideoModel]
    @Published var sheetModel: SheetModel
    @Published var updates: Int
    
    init(sheetModel: SheetModel) {
        self.sheetModel = sheetModel
        self.videoModels = []
        self.updates = 0
    }
    
    init(sheetModel: SheetModel, videoModels: [VideoModel]) {
        self.sheetModel = sheetModel
        self.videoModels = videoModels
        self.updates = 0
    }
    
    func addVideo(videoModel: VideoModel) {
        self.videoModels.append(videoModel)
    }
    
    func primaryVideo() -> VideoModel? {
        if videoModels.count >= 1 {
            return videoModels[0]
        } else {
            return nil
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
