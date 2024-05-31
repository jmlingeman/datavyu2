//
//  FileModel.swift
//  datavyu
//
//  Created by Jesse Lingeman on 6/19/23.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

public class FileModel: ReferenceFileDocument, ObservableObject, Identifiable, Equatable, Hashable {
    
    public static var readableContentTypes: [UTType] = [UTType.opf]

    var version = "#4"

    @Published var videoModels: [VideoModel]
    @Published var sheetModel: SheetModel
    @Published var updates: Int
    @Published var primaryMarker: Marker?
    @Published var primaryVideo: VideoModel?
    @Published var longestDuration: Double = 0

    var videoObservers: [NSKeyValueObservation] = []

    var currentShuttleSpeedIdx: Int = 0
    var legacyProjectSettings: ProjectFile?

    let config = Config()

    init() {
        sheetModel = SheetModel(sheetName: "default")
        videoModels = []
        updates = 0
        currentShuttleSpeedIdx = config.shuttleSpeeds.firstIndex(of: 0)!
    }

    init(sheetModel: SheetModel) {
        self.sheetModel = sheetModel
        videoModels = []
        updates = 0
        currentShuttleSpeedIdx = config.shuttleSpeeds.firstIndex(of: 0)!
    }

    init(sheetModel: SheetModel, videoModels: [VideoModel]) {
        self.sheetModel = sheetModel
        self.videoModels = videoModels
        updates = 0
        currentShuttleSpeedIdx = config.shuttleSpeeds.firstIndex(of: 0)!

        if videoModels.count > 0 {
            primaryVideo = videoModels[0]
        }

        for videoModel in videoModels {
            var observer = videoModel.player.currentItem!.observe(\.status, options: [.new, .old], changeHandler: { playerItem, _ in
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
        newFileModel.sheetModel = sheetModel.copy()
        newFileModel.videoModels = videoModels.map { vm in
            vm.copy()
        }
        newFileModel.updates = updates
        newFileModel.primaryVideo = primaryVideo
        newFileModel.longestDuration = longestDuration
        newFileModel.primaryMarker = primaryMarker

        return newFileModel
    }

    convenience init(sheetModel: SheetModel, videoModels: [VideoModel], legacyProjectSettings: ProjectFile) {
        self.init(sheetModel: sheetModel, videoModels: videoModels)
        self.legacyProjectSettings = legacyProjectSettings
    }

    func changeShuttleSpeed(step: Int) {
        if currentShuttleSpeedIdx + step < config.shuttleSpeeds.count, currentShuttleSpeedIdx + step >= 0 {
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
        updateLongestDuration()
    }

    func resetShuttleSpeed() {
        currentShuttleSpeedIdx = config.shuttleSpeeds.firstIndex(of: 0)!
    }

    func addVideo(videoUrl: URL) {
        let vm = VideoModel(videoFilePath: videoUrl)
        addVideo(videoModel: vm)
    }

    func addVideo(videoModel: VideoModel) {
        videoModels.append(videoModel)

        if videoModels.count == 1 {
            primaryVideo = videoModels[0]
        }
        
        Task {
            try await videoModel.populateMetadata()
            updateLongestDuration()
        }
    }
    
    func updateLongestDuration() {
        longestDuration = 0
        for videoModel in videoModels {
            if videoModel.duration > longestDuration {
                longestDuration = videoModel.duration
                primaryVideo = videoModel
            }
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
    
    public static func == (lhs: FileModel, rhs: FileModel) -> Bool {
        lhs.id == rhs.id
    }
    
    public func snapshot(contentType _: UTType) throws -> FileModel {
        copy()
    }
    
    public func fileWrapper(snapshot: FileModel, configuration: WriteConfiguration) throws -> FileWrapper {
        if configuration.existingFile != nil {
            let data = saveOpfFile(fileModel: snapshot, outputFilename: configuration.existingFile!.symbolicLinkDestinationURL!)
            return FileWrapper(regularFileWithContents: data)
        } else {
            return FileWrapper()
        }
    }
    
    public typealias Snapshot = FileModel
    
    public required init(configuration: ReadConfiguration) throws {
        let url = configuration.file.symbolicLinkDestinationURL
        
        let model = loadOpfFile(inputFilename: url!)
        
        videoModels = model.videoModels
        sheetModel = model.sheetModel
        primaryVideo = model.primaryVideo
        longestDuration = model.longestDuration
        primaryMarker = model.primaryMarker
        updates = model.updates
        
        currentShuttleSpeedIdx = model.currentShuttleSpeedIdx
        videoObservers = model.videoObservers
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
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
