

import SwiftUI
import UniformTypeIdentifiers

struct TracksStackView: View {
    @ObservedObject var fileModel: FileModel
    @State private var showingSaveDialog = false
    @EnvironmentObject private var appState: AppState

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
                        ForEach($fileModel.videoModels) { $videoModel in
                            TrackRowView(fileModel: fileModel, videoModel: videoModel, appState: appState)
                        }
                    }
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
                VideoView(videoModel: fileModel.videoModels.last!, sheetModel: fileModel.sheetModel)
                    .openInWindow(title: "Video: " + fileModel.videoModels.last!.getWindowTitle(), appState: appState, sender: self, frameName: fileModel.videoModels.last!.filename)
            })
        }
    }
}
