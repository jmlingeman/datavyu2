//
//  SpeechRecognizer.swift
//  datavyu
//
//  Created by Jesse Lingeman on 5/25/24.
//

import AppKit
import CoreML
import Foundation
import Speech
import WhisperKit
import Logging

public class SpeechRecognizer: ObservableObject {
    var videoModel: VideoModel?
    var sheetModel: SheetModel?
    var targetColumn: ColumnModel?
    let locale: Locale = .current
    
    @Published var transcriptionError: Bool = false
    @Published var transcriptionErrorDesc: String = ""
    
    @Published var modelState: ModelState = .unloaded
    
    var whisperKit: WhisperKit? = nil
    var audioDevices: [AudioDevice]? = nil
    var isRecording: Bool = false
    var isTranscribing: Bool = false
    var currentText: String = ""
    var currentChunks: [Int: (chunkText: [String], fallbacks: Int)] = [:]
    
    var modelStorage: String = "huggingface/models/argmaxinc/whisperkit-coreml"
    
    private var localModels: [String] = []
    private var localModelPath: String = ""
    private var availableModels: [String] = []
    private var availableLanguages: [String] = []
    private var disabledModels: [String] = WhisperKit.recommendedModels().disabled
    
    private var selectedAudioInput: String = "No Audio Input"
    private var selectedModel: String = WhisperKit.recommendedModels().default
    private var selectedLanguage: String = "english"
    private var repoName: String = "argmaxinc/whisperkit-coreml"
    private var enableTimestamps: Bool = true
    private var enablePromptPrefill: Bool = true
    private var enableCachePrefill: Bool = true
    private var enableSpecialCharacters: Bool = false
    private var enableEagerDecoding: Bool = false
    private var enableDecoderPreview: Bool = true
    private var temperatureStart: Double = 0
    private var fallbackCount: Double = 5
    private var compressionCheckWindow: Double = 60
    private var sampleLength: Double = 224
    private var silenceThreshold: Double = 0.3
    private var useVAD: Bool = true
    private var tokenConfirmationsNeeded: Double = 2
    private var chunkingStrategy: ChunkingStrategy = .none
    private var encoderComputeUnits: MLComputeUnits = .cpuAndNeuralEngine
    private var decoderComputeUnits: MLComputeUnits = .cpuAndNeuralEngine
    
    // MARK: Standard properties
    
    @Published var loadingProgressValue: Float = 0.0
    
    private var specializationProgressRatio: Float = 0.7
    private var isFilePickerPresented = false
    private var firstTokenTime: TimeInterval = 0
    private var pipelineStart: TimeInterval = 0
    private var effectiveRealTimeFactor: TimeInterval = 0
    private var effectiveSpeedFactor: TimeInterval = 0
    private var totalInferenceTime: TimeInterval = 0
    private var tokensPerSecond: TimeInterval = 0
    private var currentLag: TimeInterval = 0
    private var currentFallbacks: Int = 0
    private var currentEncodingLoops: Int = 0
    private var currentDecodingLoops: Int = 0
    private var lastBufferSize: Int = 0
    private var lastConfirmedSegmentEndSeconds: Float = 0
    private var requiredSegmentsForConfirmation: Int = 4
    private var bufferEnergy: [Float] = []
    private var bufferSeconds: Double = 0
    private var confirmedSegments: [TranscriptionSegment] = []
    private var unconfirmedSegments: [TranscriptionSegment] = []
    
    // MARK: Eager mode properties
    
    private var eagerResults: [TranscriptionResult?] = []
    private var prevResult: TranscriptionResult?
    private var lastAgreedSeconds: Float = 0.0
    private var prevWords: [WordTiming] = []
    private var lastAgreedWords: [WordTiming] = []
    private var confirmedWords: [WordTiming] = []
    private var confirmedText: String = ""
    private var hypothesisWords: [WordTiming] = []
    private var hypothesisText: String = ""
    
    // MARK: UI properties
    
    private var showComputeUnits: Bool = true
    private var showAdvancedOptions: Bool = false
    private var transcriptionTask: Task<Void, Never>? = nil
    private var transcribeFileTask: Task<Void, Never>? = nil
        
    func transcribeCurrentFile(path: String) async throws {
        let audioFileBuffer = try AudioProcessor.loadAudio(fromPath: path)
        let audioFileSamples = AudioProcessor.convertBufferToArray(buffer: audioFileBuffer)
        let transcription = try await transcribeAudioSamples(audioFileSamples)
        
        await MainActor.run {
            currentText = ""
            guard let segments = transcription?.segments else {
                return
            }
            
            self.tokensPerSecond = transcription?.timings.tokensPerSecond ?? 0
            self.effectiveRealTimeFactor = transcription?.timings.realTimeFactor ?? 0
            self.effectiveSpeedFactor = transcription?.timings.speedFactor ?? 0
            self.currentEncodingLoops = Int(transcription?.timings.totalEncodingRuns ?? 0)
            self.firstTokenTime = transcription?.timings.firstTokenTime ?? 0
            self.pipelineStart = transcription?.timings.pipelineStart ?? 0
            self.currentLag = transcription?.timings.decodingLoop ?? 0
            
            self.confirmedSegments = segments
        }
    }
    
    func transcribeAudioSamples(_ samples: [Float]) async throws -> TranscriptionResult? {
        guard let whisperKit = whisperKit else { return nil }
        
        let languageCode = Constants.languages[selectedLanguage, default: Constants.defaultLanguageCode]
        let task: DecodingTask = .transcribe
        let seekClip: [Float] = []
        
        let options = DecodingOptions(
            verbose: true,
            task: task,
            language: languageCode,
            temperature: Float(temperatureStart),
            temperatureFallbackCount: Int(fallbackCount),
            sampleLength: Int(sampleLength),
            usePrefillPrompt: enablePromptPrefill,
            usePrefillCache: enableCachePrefill,
            skipSpecialTokens: !enableSpecialCharacters,
            withoutTimestamps: !enableTimestamps,
            clipTimestamps: seekClip,
            chunkingStrategy: chunkingStrategy
        )
        
        // Early stopping checks
        let decodingCallback: ((TranscriptionProgress) -> Bool?) = { (progress: TranscriptionProgress) in
            DispatchQueue.main.async {
                let fallbacks = Int(progress.timings.totalDecodingFallbacks)
                let chunkId = progress.windowId
                
                // First check if this is a new window for the same chunk, append if so
                var updatedChunk = (chunkText: [progress.text], fallbacks: fallbacks)
                if var currentChunk = self.currentChunks[chunkId], let previousChunkText = currentChunk.chunkText.last {
                    if progress.text.count >= previousChunkText.count {
                        // This is the same window of an existing chunk, so we just update the last value
                        currentChunk.chunkText[currentChunk.chunkText.endIndex - 1] = progress.text
                        updatedChunk = currentChunk
                    } else {
                        // Fallback, overwrite the previous bad text
                        updatedChunk.chunkText[currentChunk.chunkText.endIndex - 1] = progress.text
                        updatedChunk.fallbacks = fallbacks
                        print("Fallback occured: \(fallbacks)")
                        
                    }
                }
                
                // Set the new text for the chunk
                self.currentChunks[chunkId] = updatedChunk
                let joinedChunks = self.currentChunks.sorted { $0.key < $1.key }.flatMap { $0.value.chunkText }.joined(separator: "\n")
                
                self.currentText = joinedChunks
                self.currentFallbacks = fallbacks
                self.currentDecodingLoops += 1
            }
            
            // Check early stopping
            let currentTokens = progress.tokens
            let checkWindow = Int(self.compressionCheckWindow)
            if currentTokens.count > checkWindow {
                let checkTokens: [Int] = currentTokens.suffix(checkWindow)
                let compressionRatio = compressionRatio(of: checkTokens)
                if compressionRatio > options.compressionRatioThreshold! {
                    return false
                }
            }
            if progress.avgLogprob! < options.logProbThreshold! {
                return false
            }
            return nil
        }
        
        let transcriptionResults: [TranscriptionResult] = try await whisperKit.transcribe(
            audioArray: samples,
            decodeOptions: options,
            callback: decodingCallback
        )
        
        let mergedResults = mergeTranscriptionResults(transcriptionResults)
        
        return mergedResults
    }
    
    func getComputeOptions() -> ModelComputeOptions {
        return ModelComputeOptions(audioEncoderCompute: encoderComputeUnits, textDecoderCompute: decoderComputeUnits)
    }
    
    func updateProgressBar(targetProgress: Float, maxTime: TimeInterval) async {
        let initialProgress = loadingProgressValue
        let decayConstant = -log(1 - targetProgress) / Float(maxTime)
        
        let startTime = Date()
        
        while true {
            let elapsedTime = Date().timeIntervalSince(startTime)
            
            // Break down the calculation
            let decayFactor = exp(-decayConstant * Float(elapsedTime))
            let progressIncrement = (1 - initialProgress) * (1 - decayFactor)
            let currentProgress = initialProgress + progressIncrement
            
            await MainActor.run {
                loadingProgressValue = currentProgress
            }
            
            if currentProgress >= targetProgress {
                break
            }
            
            do {
                try await Task.sleep(nanoseconds: 100_000_000)
            } catch {
                break
            }
        }
    }
    
    func loadModel(_ model: String, redownload: Bool = false) async throws {
        print("Selected Model: \(UserDefaults.standard.string(forKey: "selectedModel") ?? "nil")")
        
        whisperKit = nil
//        Task {
            whisperKit = try await WhisperKit(
                computeOptions: getComputeOptions(),
                verbose: true,
                logLevel: .debug,
                prewarm: false,
                load: false,
                download: false
            )
            guard let whisperKit = whisperKit else {
                return
            }
            
            var folder: URL?
            
            // Check if the model is available locally
            if localModels.contains(model) && !redownload {
                // Get local model folder URL from localModels
                // TODO: Make this configurable in the UI
                folder = URL(fileURLWithPath: localModelPath).appendingPathComponent(model)
            } else {
                // Download the model
                folder = try await WhisperKit.download(variant: model, from: repoName, progressCallback: { progress in
                    DispatchQueue.main.async { [self] in
                        self.loadingProgressValue = Float(progress.fractionCompleted) * specializationProgressRatio
                        print(self.loadingProgressValue)
                        modelState = .downloading
                    }
                })
            }
            
            await MainActor.run {
                loadingProgressValue = specializationProgressRatio
                modelState = .downloaded
            }
            
            if let modelFolder = folder {
                whisperKit.modelFolder = modelFolder
                
                await MainActor.run {
                    // Set the loading progress to 90% of the way after prewarm
                    loadingProgressValue = specializationProgressRatio
                    modelState = .prewarming
                }
                
                let progressBarTask = Task {
                    await updateProgressBar(targetProgress: 0.9, maxTime: 240)
                }
                
                // Prewarm models
                do {
                    try await whisperKit.prewarmModels()
                    progressBarTask.cancel()
                } catch {
                    print("Error prewarming models, retrying: \(error.localizedDescription)")
                    progressBarTask.cancel()
                    if !redownload {
                        try await loadModel(model, redownload: true)
                        return
                    } else {
                        // Redownloading failed, error out
                        modelState = .unloaded
                        return
                    }
                }
                
                await MainActor.run {
                    // Set the loading progress to 90% of the way after prewarm
                    loadingProgressValue = specializationProgressRatio + 0.9 * (1 - specializationProgressRatio)
                    modelState = .loading
                }
                
                try await whisperKit.loadModels()
                
                await MainActor.run {
                    if !localModels.contains(model) {
                        localModels.append(model)
                    }
                    
                    availableLanguages = Constants.languages.map { $0.key }.sorted()
                    loadingProgressValue = 1.0
                    modelState = whisperKit.modelState
                }
//            }
        }
    }
    
    func transcribeFile(path: String) {
//        resetState()
        whisperKit?.audioProcessor = AudioProcessor()
        self.transcribeFileTask = Task {
            do {
                try await transcribeCurrentFile(path: path)
            } catch {
                print("File selection error: \(error.localizedDescription)")
            }
            
            let fullTranscript = formatSegments(confirmedSegments + unconfirmedSegments, withTimestamps: enableTimestamps).joined(separator: "\n")
            print(fullTranscript)
        }
    }
    
    func run(videoModel: VideoModel, sheetModel: SheetModel?, targetColumn: ColumnModel?) {
        self.videoModel = videoModel
        self.sheetModel = sheetModel
        self.targetColumn = targetColumn
//        Task {
//            selectedModel = "large-v3"
//            do {
//                try await loadModel("large-v3")
//            }
//            transcribeFile(path: videoModel.videoFileURL.path)
//        }
            Task {
                do {
                    print("started")
                    // try await print(WhisperKit.fetchAvailableModels())
                    
                    let whisperKit = try await WhisperKit(verbose: true, logLevel: .debug)
                    
                    let result = try await whisperKit.transcribe(audioPath: videoModel.videoFileURL.path)
                    
                    await MainActor.run {
                        let test = mergeTranscriptionResults(result)
                        if sheetModel != nil && targetColumn != nil {
                            for txRes in result {
                                print(txRes)
                                for segment in txRes.segments {
                                    let onset = segment.start
                                    let offset = segment.end
                                    let text = segment.text
                                    
                                    let cell = targetColumn?.addCell()
                                    cell?.setOnset(onset: Int(onset * 1000))
                                    cell?.setOffset(offset: Int(offset * 1000))
                                    cell?.setArgumentValue(index: 0, value: text)
                                }
                                
                            }
                        }
                    }
                } catch {
                    print(error.localizedDescription)
                }
            }
        
        
//        SFSpeechRecognizer.requestAuthorization { authStatus in
//            if authStatus == SFSpeechRecognizerAuthorizationStatus.authorized {
//                // Create a speech recognizer associated with the user's default language.
//                guard let myRecognizer = SFSpeechRecognizer() else {
//                    // The system doesn't support the user's default language.
//                    return
//                }
//
//                guard myRecognizer.isAvailable else {
//                    // The recognizer isn't available.
//                    return
//                }
//
//                // Create and execute a speech recognition request for the audio file at the URL.
//                let request = SFSpeechURLRecognitionRequest(url: self.videoModel.videoFileURL)
//                request.requiresOnDeviceRecognition = true
//                myRecognizer.recognitionTask(with: request) { (result, error) in
//                    guard let result else {
//                        // Recognition failed, so check the error for details and handle it.
//                        if error != nil {
//                            self.transcriptionError = true
//                            self.transcriptionErrorDesc = "\(error!)"
//                        }
//                        return
//                    }
//
//                    // Print the speech transcription with the highest confidence that the
//                    // system recognized.
//                    if result.isFinal {
//                        print(result.bestTranscription.formattedString)
//                    }
//                }
//            }
//        }
    }
}
