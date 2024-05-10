//
//  FileModel.swift
//  datavyu
//
//  Created by Jesse Lingeman on 6/19/23.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

class FileModel: ReferenceFileDocument, ObservableObject, Identifiable {
    func snapshot(contentType: UTType) throws -> FileModel {
        return self.copy()
    }
    
    func fileWrapper(snapshot: FileModel, configuration: WriteConfiguration) throws -> FileWrapper {
        if configuration.existingFile != nil {
            let data = saveOpfFile(fileModel: snapshot, outputFilename: configuration.existingFile!.symbolicLinkDestinationURL!)
            return FileWrapper(regularFileWithContents: data)
        } else {
            return FileWrapper()
        }
    }
    
    typealias Snapshot = FileModel
    
    required init(configuration: ReadConfiguration) throws {
        let url = configuration.file.symbolicLinkDestinationURL
        
        let model = loadOpfFile(inputFilename: url!)
                
        self.videoModels = model.videoModels
        self.sheetModel = model.sheetModel
        self.primaryVideo = model.primaryVideo
        self.longestDuration = model.longestDuration
        self.primaryMarker = model.primaryMarker
        self.updates = model.updates
        
        self.currentShuttleSpeedIdx = model.currentShuttleSpeedIdx
        self.videoObservers = model.videoObservers
    }
    
    static var readableContentTypes: [UTType] = [UTType.opf]
    
    
    var version = "#4"
    
    @Published var videoModels: [VideoModel]
    @Published var sheetModel: SheetModel
    @Published var updates: Int
    @Published var primaryMarker : Marker?
    @Published var primaryVideo : VideoModel?
    @Published var longestDuration : Double = 0
    
    var videoObservers: [NSKeyValueObservation] = []
    
    var currentShuttleSpeedIdx: Int = 0
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
    
    func copy() -> FileModel {
        let newFileModel = FileModel()
        newFileModel.sheetModel = self.sheetModel.copy()
        newFileModel.videoModels = self.videoModels.map({ vm in
            vm.copy()
        })
        newFileModel.updates = self.updates
        newFileModel.primaryVideo = self.primaryVideo
        newFileModel.longestDuration = self.longestDuration
        newFileModel.primaryMarker = self.primaryMarker
        
        return newFileModel
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
