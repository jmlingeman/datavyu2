//
//  TrackRowView.swift
//  Datavyu2
//
//  Created by Jesse Lingeman on 6/3/24.
//

import SwiftUI

struct TrackRowView: View {
    @ObservedObject var fileModel: FileModel
    @ObservedObject var videoModel: VideoModel
    @ObservedObject var appState: AppState
    @State var volume: Float = 1.0
    @State var showingVolumeControl: Bool = false
    var body: some View {
        GridRow {
            //                                HStack {
            Text(videoModel.videoFileURL.lastPathComponent).frame(width: 150)
            Menu(content: {
                Button("Generate Spectrogram") {
                    let savePanel = NSSavePanel()
                    savePanel.allowedContentTypes = [UTType.mpeg4Movie, UTType.quickTimeMovie, UTType.video]
                    savePanel.directoryURL = videoModel.videoFileURL.deletingLastPathComponent()
                    savePanel.nameFieldStringValue = "\(videoModel.videoFileURL.lastPathComponent)-spectrogram.mov"
                    if savePanel.runModal() == .OK {
                        SpectrogramProgressView(outputPath: savePanel.url!, videoModel: videoModel, fileModel: fileModel)
                            .openInWindow(title: "Spectrogram Generation: \(videoModel.videoFileURL.lastPathComponent)", appState: appState, sender: self, frameName: nil)
                    }
                }
                Button("Transcribe Video") {
                    let transcribePanel = TranscriptionSettingsView(sheetModel: fileModel.sheetModel, videoModel: videoModel)
                    transcribePanel.openInWindow(title: "Transcription Settings", appState: appState, sender: self, frameName: nil)
                }
            }, label: {
                Image(systemName: "ellipsis.circle.fill")
            }).menuIndicator(.hidden).buttonBorderShape(.capsule).frame(width: 30)

            Button {
                videoModel.isHidden.toggle()
                if videoModel.isHidden {
                    appState.hideWindow(fileModel: fileModel, title: videoModel.getWindowTitle())
                } else {
                    appState.showWindow(fileModel: fileModel, title: videoModel.getWindowTitle())
                }
            } label: {
                Image(systemName: videoModel.isHidden ? "eye.slash.fill" : "eye.fill")
            }

            Button {
                showingVolumeControl.toggle()
            } label: {
                Image(systemName: volume == 0 ? "speaker.slash.fill" : volume == 1 ? "speaker.wave.3.fill" : "speaker.wave.1.fill")
            }.popover(isPresented: $showingVolumeControl, content: {
                Slider(value: $volume, in: 0.0 ... 1.0) {
                    Image(systemName: volume == 0 ? "speaker.slash.fill" : "speaker.wave.1.fill")
                } minimumValueLabel: {
                    Image(systemName: "speaker.slash.fill")
                } maximumValueLabel: {
                    Image(systemName: "speaker.wave.3.fill")
                }.frame(width: 300)
                    .onChange(of: volume) { _, newValue in
                        videoModel.changeVolume(newVolume: newValue)
                    }

            })

            TrackView(videoModel: videoModel,
                      fileModel: fileModel,
                      primaryMarker: $fileModel.primaryMarker)
                .onTapGesture {
                    fileModel.updates += 1
                    videoModel.updates += 1
                }.overlay {
                    if fileModel.videoModels.count > 0 {
                        TrackPositionIndicator(fileModel: fileModel, videoModel: fileModel.primaryVideo!)
                    }
                }.frame(maxWidth: .infinity)
        }.frame(height: 30)
    }
}
