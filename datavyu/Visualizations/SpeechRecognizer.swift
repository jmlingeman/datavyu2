//
//  SpeechRecognizer.swift
//  datavyu
//
//  Created by Jesse Lingeman on 5/25/24.
//

import AppKit
import CoreML
import Foundation
import Logging
import Speech
import SwiftUI
import WhisperKit

public class SpeechRecognizer: ObservableObject {
    var videoModel: VideoModel?
    var sheetModel: SheetModel?
    var targetColumn: ColumnModel?
    var targetArgument: Argument?
    let locale: Locale = .current

    @Published var transcriptionError: Bool = false
    @Published var transcriptionErrorDesc: String = ""

    @Published var modelState: ModelState = .unloaded

    @Published var availableModels: [String] = []
    @Published var defaultModel: String = ""

    @Published var downloadProgress: Double = 0

    var whisperKit: WhisperKitProgress? = nil

    init() {
        populateAvailableModels()
        Task {
            try await self.whisperKit = WhisperKitProgress()
        }
    }

    func initializeWhisperKit(model: String) {
        Task {
            try await whisperKit?.initialize(model: model)
        }
    }

    func checkModelInstalled(model: String) -> Bool {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let url = NSURL(fileURLWithPath: path)
        if let pathComponent = url.appendingPathComponent(model) {
            let filePath = pathComponent.path
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: filePath) {
                return true
            } else {
                return false
            }
        } else {
            return false
        }
    }

    func populateAvailableModels() {
        Task {
            let models = try await WhisperKit.fetchAvailableModels()
            let (recommendedModel, disabledModels) = WhisperKit.recommendedModels()

            DispatchQueue.main.async {
                self.availableModels.removeAll { model in
                    disabledModels.contains { disabledModel in
                        model == disabledModel
                    }
                }
                self.defaultModel = recommendedModel
                self.availableModels = models
            }
        }
    }

    func run(selectedModel: String, videoModel: VideoModel, sheetModel: SheetModel?, targetColumn: ColumnModel?, targetArgument: Argument?) {
        self.videoModel = videoModel
        self.sheetModel = sheetModel
        self.targetColumn = targetColumn
        self.targetArgument = targetArgument

        Task {
            do {
                Logger.info("started")

                if whisperKit == nil {
                    whisperKit = try await WhisperKitProgress(model: selectedModel, logLevel: Logging.LogLevel.debug)
                }

                let argIdx = targetColumn!.getArgumentIndex(targetArgument)!
                let result = try await whisperKit!.transcribe(audioPath: videoModel.videoFileURL.path)

                await MainActor.run {
                    if sheetModel != nil, targetColumn != nil {
                        for txRes in result {
                            Logger.info(txRes)
                            for segment in txRes.segments {
                                let onset = segment.start
                                let offset = segment.end
                                let text = segment.text

                                let textTagsRemoved = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines)

                                let cell = targetColumn?.addCell()
                                cell?.setOnset(onset: Int(onset * 1000))
                                cell?.setOffset(offset: Int(offset * 1000))
                                cell?.setArgumentValue(index: argIdx, value: textTagsRemoved)
                            }
                        }
                    }
                }
            } catch {
                Logger.info(error.localizedDescription)
            }
        }
    }
}

public class WhisperKitProgress: WhisperKit, ObservableObject {
    @Published var downloadProgress: Double = 0

    var model: String? = nil
    var downloadBase: URL? = nil
    var modelRepo: String? = nil

    override public init(
        model: String? = nil,
        downloadBase _: URL? = nil,
        modelRepo: String? = nil,
        modelFolder _: String? = nil,
        tokenizerFolder _: URL? = nil,
        computeOptions _: ModelComputeOptions? = nil,
        audioProcessor _: (any AudioProcessing)? = nil,
        featureExtractor _: (any FeatureExtracting)? = nil,
        audioEncoder _: (any AudioEncoding)? = nil,
        textDecoder _: (any TextDecoding)? = nil,
        logitsFilters _: [any LogitsFiltering]? = nil,
        segmentSeeker _: (any SegmentSeeking)? = nil,
        verbose _: Bool = true,
        logLevel _: Logging.LogLevel = .info,
        prewarm _: Bool? = nil,
        load _: Bool? = nil,
        download _: Bool = true,
        useBackgroundDownloadSession _: Bool = false
    ) async throws {
        try await super.init()

        self.model = model
        self.modelRepo = modelRepo

        downloadBase = Paths.transcriptionFolder
        Paths.createDirectory(directory: downloadBase!)
    }

    func initialize(
        model: String,
        download: Bool = true,
        modelFolder: String? = nil,
        prewarm: Bool? = nil,
        load: Bool? = nil
    ) async throws {
        self.model = model

        try await setupModelsProgress(
            model: model,
            downloadBase: downloadBase,
            modelRepo: modelRepo,
            modelFolder: modelFolder,
            download: download
        )

        if let prewarm = prewarm, prewarm {
            Logging.info("Prewarming models...")
            try await prewarmModels()
        }

        // If load is not passed in, load based on whether a modelFolder is passed
        if load ?? (modelFolder != nil) {
            Logging.info("Loading models...")
            try await loadModels()
        }
    }

    func setupModelsProgress(
        model: String?,
        downloadBase: URL? = nil,
        modelRepo: String?,
        modelFolder: String?,
        download: Bool
    ) async throws {
        // Determine the model variant to use
        let modelVariant = model ?? WhisperKit.recommendedModels().default

        // If a local model folder is provided, use it; otherwise, download the model
        if let folder = modelFolder {
            self.modelFolder = URL(fileURLWithPath: folder)
        } else if download {
            let repo = modelRepo ?? "argmaxinc/whisperkit-coreml"
            do {
                self.modelFolder = try await Self.download(
                    variant: modelVariant,
                    downloadBase: downloadBase,
                    useBackgroundSession: useBackgroundDownloadSession,
                    from: repo,
                    progressCallback: { progress in
                        Logger.info(progress)
                        self.downloadProgress = progress.fractionCompleted
                    }
                )
            } catch {
                // Handle errors related to model downloading
                throw WhisperError.modelsUnavailable("""
                Model not found. Please check the model or repo name and try again.
                Error: \(error)
                """)
            }
        }
    }
}
