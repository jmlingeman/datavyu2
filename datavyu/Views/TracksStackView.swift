

import SwiftUI
import UniformTypeIdentifiers

struct TracksStackView: View {
    @ObservedObject var fileModel: FileModel
    @State private var showingSaveDialog = false


    func syncVideos() {
        if fileModel.primaryVideo != nil, fileModel.videoModels.count > 1, fileModel.primaryVideo!.selectedMarker != nil {
            fileModel.primaryVideo!.syncMarker = fileModel.primaryVideo!.selectedMarker
            fileModel.primaryMarker = fileModel.primaryVideo!.syncMarker
            for videoModel in fileModel.videoModels {
                if videoModel != fileModel.primaryVideo {
                    let time = videoModel.selectedMarker?.time
                    if time != nil {
                        videoModel.syncMarker = videoModel.selectedMarker
                        videoModel.syncOffset = videoModel.syncMarker!.time - fileModel.primaryMarker!.time
                    }
                }
            }
            fileModel.seekAllVideos(to: fileModel.primaryMarker!.time)
        }
    }

    func addVideo() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.video, .quickTimeMovie, .mpeg, .mpeg4Movie, .mp3, .mpeg2Video, .mpeg2TransportStream]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK {
            fileModel.addVideo(videoUrl: panel.url!)
            fileModel.updates += 1
        }
    }

    func getTrackWidthProportion(videoModel: VideoModel) -> Double {
        videoModel.duration / fileModel.longestDuration
    }

    var body: some View {
        Grid {
            GridRow {
                GeometryReader { _ in
                    Grid {
                        ForEach(fileModel.videoModels) { videoModel in
                            GridRow {
                                HStack {
                                    Text(videoModel.videoFileURL.lastPathComponent).frame(width: 150)
                                    Menu(content: {
                                        Button("Generate Spectrogram") {
                                            let savePanel = NSSavePanel()
                                            savePanel.allowedContentTypes = [UTType.mpeg4Movie, UTType.quickTimeMovie, UTType.video]
                                            savePanel.directoryURL = videoModel.videoFileURL.deletingLastPathComponent()
                                            savePanel.nameFieldStringValue = "\(videoModel.videoFileURL.lastPathComponent)-spectrogram.mov"
                                            if savePanel.runModal() == .OK {
                                                SpectrogramProgressView(outputPath: savePanel.url!, videoModel: videoModel, fileModel: fileModel).openInWindow(title: "Spectrogram Generation: \(videoModel.videoFileURL.lastPathComponent)", sender: self, frameName: nil)
                                            }
                                            
                                        }
                                    }, label: {
                                        Image(systemName: "ellipsis.circle.fill")
                                    }).menuIndicator(.hidden).buttonBorderShape(.capsule).frame(width: 30)
                                    
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
                                        }
                                }
                            }.frame(height: 30)
                        }
                    }
                }
            }
            GridRow {
                if fileModel.primaryVideo != nil {
                    ClockView(videoModel: fileModel.primaryVideo!)
                }
            }

        }.overlay(alignment: .bottomTrailing) {
            overlayButtons
        }
    }

    var overlayButtons: some View {
        HStack(alignment: .bottom) {
            Spacer()
            Button("Sync Videos", action: syncVideos)
            Button("Add Video", action: {
                addVideo()
                VideoView(videoModel: fileModel.videoModels.last!, sheetModel: fileModel.sheetModel).openInWindow(title: fileModel.videoModels.last!.filename, sender: self, frameName: fileModel.videoModels.last!.filename)
            })
        }
    }
}

// struct TracksStackView_Previews: PreviewProvider {
//    static var previews: some View {
//        TracksStackView(videoModels: [VideoModel(videoFilePath: "IMG_1234")])
//    }
// }
