

import SwiftUI
import UniformTypeIdentifiers

struct TracksStackView: View {
    @ObservedObject var fileModel: FileModel
    @State private var showingSaveDialog = false
    @EnvironmentObject private var appState: AppState

    @State var trackPosStart: CGFloat = 0

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
                GeometryReader { gr in
                    ZStack {
                        Grid {
                            ForEach($fileModel.videoModels) { $videoModel in
                                TrackRowView(fileModel: fileModel, videoModel: videoModel, appState: appState).onAppear {
                                    trackPosStart = gr.frame(in: .global).minX
                                    print(trackPosStart)
                                }
                            }
                        }
                    }
                }
            }
            GridRow {
                overlayButtons
            }

        }.overlay(alignment: .leading) {
            GeometryReader { gr in
                TrackSnapOverlay(gr: gr, fileModel: fileModel)
            }
        }
    }

    var overlayButtons: some View {
        VStack {
            HStack {
                Spacer()
                Button("Snap Region") {
                    appState.fileController?.activeFileModel.snapToRegion()
                }
                Button("Clear Region") {
                    appState.fileController?.activeFileModel.clearRegion()
                }
                Button("Lock All") {
                    // TODO: Implement track locking.
                }
            }
            HStack(alignment: .bottom) {
                Spacer()
                Button(appState.highlightMode ? "Enable Cell Highlighting" : "Disable Cell Highlighting") {
                    // TODO: highlight and focus
                    appState.toggleHighlightMode()
                }
                Button(appState.focusMode ? "Enable Highlight + Focus" : "Disable Highlight + Focus") {
                    // TODO: highlight and focus
                    appState.toggleFocusMode()
                }
                Button("Sync Videos", action: syncVideos)
                Button("Add Video", action: {
                    addVideo()
                })
            }
        }
    }
}
