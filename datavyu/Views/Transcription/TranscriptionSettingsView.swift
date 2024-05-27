//
//  TranscriptionSettingsView.swift
//  datavyu
//
//  Created by Jesse Lingeman on 5/27/24.
//

import SwiftUI

struct TranscriptionSettingsView: View {
    @ObservedObject var sheetModel: SheetModel
    @ObservedObject var videoModel: VideoModel
    @State var selectedColumn: ColumnModel = ColumnModel()
    @State var selectedArgument: Argument = Argument()
    @State var selectedModel: String = "openai_whisper-large-v3"
    @StateObject var speech = SpeechRecognizer()
    
    @State var ready: Bool = false
    @State var running: Bool = false
    
    @State var downloadProgress: Double = 0
    @State var transcriptionProgress: Double = 0
    
    @Environment(\.dismiss) var dismiss
    
    
    
    let timer = Timer.publish(every: 2.0, on: .main, in: .common).autoconnect()    //  seconds
    

    
    var body: some View {
        VStack {
            Picker("Available Models", selection: $selectedModel) {
                ForEach(speech.availableModels, id: \.self) { model in
                    Text(model).tag(model)
                }
            }.disabled(running)
            
            Button("Download Model Files") {
                speech.initializeWhisperKit(model: selectedModel)
            }.onChange(of: selectedModel) { oldValue, newValue in
                if speech.checkModelInstalled(model: newValue) {
                    ready = true
                }
            }.disabled(running)
            
            Text(String(format: "%.2f%% downloaded", downloadProgress * 100))
            ProgressView(value: downloadProgress).onReceive(timer) { _ in
                downloadProgress = speech.whisperKit!.downloadProgress
            }.padding()
            

            
            Picker("Select column to transcribe in to:", selection: $selectedColumn) {
                ForEach(sheetModel.columns) { column in
                    Text(column.columnName).tag(column)
                }
            }.disabled(running)
            
            Picker("Select argument:", selection: $selectedArgument) {
                ForEach(selectedColumn.arguments) { argument in
                    Text(argument.name).tag(argument)
                }
            }.disabled(running)
            
            Text("Notes on transcription:")
            Text("1: The first time transcription is run on each computer,")
            Text("it must download ~3GB of model files.").font(.body)
            Text("2: The output is from an unsupervised machine learning model")
            Text("and may contain both false positive and false negative errors.").font(.body)
            Text("3: Transcription may take a long time.").font(.body)
            Text("4. Transcription requires an M-series Mac.").font(.body)
            Text("5: Some models only available when using M2+ series Macs.").font(.body)
            
            Button("Start Transcription") {
                let targetColumn = selectedColumn
                running = true
                speech.run(selectedModel: selectedModel, videoModel: videoModel, sheetModel: sheetModel, targetColumn: selectedColumn, targetArgument: selectedArgument)
            }.disabled(running || selectedColumn.columnName.count == 0 || selectedArgument.name.count == 0)
            
            Text(String(format: "%.2f%% transcribed", transcriptionProgress * 100))
            ProgressView(value: transcriptionProgress).onReceive(timer) { _ in
                transcriptionProgress = speech.whisperKit!.progress.fractionCompleted
                if transcriptionProgress == 1.0 {
                    running = false
                }
            }
            
            Button("Cancel") {
                dismiss()
            }.disabled(running)
        }.padding()
    }
}
