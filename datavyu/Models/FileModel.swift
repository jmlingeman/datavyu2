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
    
    init(sheetModel: SheetModel) {
        self.sheetModel = sheetModel
        self.videoModels = []
    }
    
    init(sheetModel: SheetModel, videoModels: [VideoModel]) {
        self.sheetModel = sheetModel
        self.videoModels = videoModels
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
}
