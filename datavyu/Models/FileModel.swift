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
    public static var writableContentTypes: [UTType] = [UTType.opf]

    public static let type = "com.datavyu.opf"

    var version = "#4"

    @Published var videoModels: [VideoModel]
    @Published var sheetModel: SheetModel
    @Published var updates: Int
    @Published var primaryMarker: Marker?
    @Published var primaryVideo: VideoModel?
    @Published var longestDuration: Double = 0

    @Published var videoController: VideoController?

    @Published var leftRegionTime: Double = 0
    @Published var rightRegionTime: Double = .greatestFiniteMagnitude

    @Published var unsavedChanges: Bool = false

    @Published var fileURL: URL?
    @Published var associatedScripts: [URL] = []
    var videoObservers: [NSKeyValueObservation] = []

    var legacyProjectSettings: ProjectFile?

    init() {
        sheetModel = SheetModel(sheetName: "default")
        videoModels = []
        updates = 0
        videoController = VideoController(fileModel: self)

        setFileModelForSheet()
    }

    init(sheetModel: SheetModel) {
        self.sheetModel = sheetModel
        videoModels = []
        updates = 0
        videoController = VideoController(fileModel: self)

        setFileModelForSheet()
    }

    init(sheetModel: SheetModel, videoModels: [VideoModel]) {
        self.sheetModel = sheetModel
        self.videoModels = videoModels
        updates = 0

        if videoModels.count > 0 {
            primaryVideo = videoModels[0]
            setPrimaryVideo(primaryVideo!)
        }

        for videoModel in videoModels {
            var observer = videoModel.player.currentItem!.observe(\.status, options: [.new, .old], changeHandler: { playerItem, _ in
                if playerItem.status == .readyToPlay {
                    videoModel.ready = true
                    videoModel.duration = videoModel.player.getCurrentTrackDuration()

                    if videoModel.duration > self.longestDuration {
                        self.longestDuration = videoModel.duration
                        self.setPrimaryVideo(videoModel)
                    }
                }
            })
            videoObservers.append(observer)
        }
        videoController = VideoController(fileModel: self)

        setFileModelForSheet()
    }

    func setFileModelForSheet() {
        sheetModel.fileModel = self
    }

    func setPrimaryVideo(_ video: VideoModel) {
        primaryVideo = video
        for videoModel in videoModels {
            videoModel.isPrimaryVideo = false
        }
        primaryVideo?.isPrimaryVideo = true
    }

    func configVideoController() {
        videoController = VideoController(fileModel: self)
    }

    func snapToRegion() {
        if sheetModel.focusController.focusedCell != nil {
            leftRegionTime = millisToSeconds(millis: sheetModel.focusController.focusedCell!.onset)
            rightRegionTime = millisToSeconds(millis: sheetModel.focusController.focusedCell!.offset)
        }
    }

    func clearRegion() {
        leftRegionTime = -0.05
        rightRegionTime = primaryVideo?.getDuration() ?? 0 + 0.05
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

    func setFileURL(url: URL) {
        fileURL = url
        loadAssociatedScripts()
    }

    func setFileChanged() {
        DispatchQueue.main.async {
            self.unsavedChanges = true
        }
    }

    func setFileSaved() {
        unsavedChanges = false
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

        setFileChanged()
    }

    func addVideo(videoUrl: URL) {
        let vm = VideoModel(videoFilePath: videoUrl)
        addVideo(videoModel: vm)
    }

    func addVideo(videoModel: VideoModel) {
        videoModels.append(videoModel)

        if videoModels.count == 1 {
            setPrimaryVideo(videoModels[0])
        }

        Task {
            try await videoModel.populateMetadata()
            updateLongestDuration()
        }

        setFileChanged()
    }

    func updateLongestDuration() {
        DispatchQueue.main.async {
            self.longestDuration = 0
            for videoModel in self.videoModels {
                if videoModel.duration > self.longestDuration {
                    self.longestDuration = videoModel.duration
                    self.primaryVideo = videoModel
                }
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

    private func getScriptsKey() -> String? {
        if fileURL != nil {
            return "\(fileURL!.path()) -- associatedScripts"
        }
        return nil
    }

    public func addAssociatedScript(url: URL) {
        if fileURL != nil {
            associatedScripts.append(url)
            UserDefaults.standard.set(associatedScripts, forKey: getScriptsKey()!)
        }
    }

    public func loadAssociatedScripts() {
        if fileURL != nil {
            associatedScripts = UserDefaults.standard.object(forKey: getScriptsKey()!) as? [URL] ?? []
        }
    }

    public func fileWrapper(snapshot: FileModel, configuration: WriteConfiguration) throws -> FileWrapper {
        if configuration.existingFile != nil {
            if configuration.existingFile!.isSymbolicLink {
                let data = saveOpfFile(fileModel: snapshot, outputFilename: configuration.existingFile!.symbolicLinkDestinationURL!)
                return FileWrapper(symbolicLinkWithDestinationURL: configuration.existingFile!.symbolicLinkDestinationURL!)
//                return FileWrapper(regularFileWithContents: data)
            } else {
                if snapshot.fileURL != nil {
                    let data = saveOpfFile(fileModel: snapshot, outputFilename: snapshot.fileURL!)
                    return FileWrapper(symbolicLinkWithDestinationURL: snapshot.fileURL!)
                } else {
                    let data = saveOpfFile(fileModel: snapshot, outputFilename: nil, writeFile: false)
                    return FileWrapper(regularFileWithContents: data)
                }
            }
        } else {
            let data = saveOpfFile(fileModel: snapshot, outputFilename: nil, writeFile: false)
            return FileWrapper(regularFileWithContents: data)
        }
    }

    public typealias Snapshot = FileModel

    public required init(configuration: ReadConfiguration) throws {
        Logger.info("Reg: \(configuration.file.isRegularFile) Sym: \(configuration.file.isSymbolicLink)")

        if configuration.file.isSymbolicLink {
            let url = configuration.file.symbolicLinkDestinationURL
            let model = loadOpfFile(inputFilename: url!)

            videoModels = model.videoModels
            sheetModel = model.sheetModel
            primaryVideo = model.primaryVideo
            longestDuration = model.longestDuration
            primaryMarker = model.primaryMarker
            updates = model.updates

            videoObservers = model.videoObservers
            videoController = VideoController(fileModel: self)
        } else {
            let model = loadOpfData(data: configuration.file.regularFileContents!)
            videoModels = model.videoModels
            sheetModel = model.sheetModel
            primaryVideo = model.primaryVideo
            longestDuration = model.longestDuration
            primaryMarker = model.primaryMarker
            updates = model.updates

            videoObservers = model.videoObservers
            videoController = VideoController(fileModel: self)
        }
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public func fileWrapper(configuration _: WriteConfiguration) throws -> FileWrapper {
        let data = saveOpfFile(fileModel: self, outputFilename: fileURL!)
        return FileWrapper(serializedRepresentation: data)!
    }

    public func lockVideos() {
        for videoModel in videoModels {
            videoModel.locked = true
        }
    }

    public func unlockVideos() {
        for videoModel in videoModels {
            videoModel.locked = false
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
