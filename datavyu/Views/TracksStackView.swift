

import SwiftUI
import UniformTypeIdentifiers

struct TracksStackView: View {
    @ObservedObject var fileModel: FileModel
    @State private var showingSaveDialog = false
    @EnvironmentObject private var appState: AppState

    @State var trackPosStart: CGFloat = 0
    @State var trackZoomFactor: CGFloat = 1
    @State var videoLoaded: Bool = false
    @State var allTracksLocked: Bool = false

    func syncVideos() {
        if fileModel.primaryVideo != nil, fileModel.videoModels.count > 1, fileModel.primaryVideo!.selectedMarker != nil {
            fileModel.primaryVideo!.syncMarker = fileModel.primaryVideo!.selectedMarker
            fileModel.primaryMarker = fileModel.primaryVideo!.syncMarker
            for videoModel in fileModel.videoModels {
                if videoModel != fileModel.primaryVideo, videoModel.locked == false {
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
            videoLoaded = true
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
                        ScrollView(.horizontal) {
                            Grid {
                                ForEach($fileModel.videoModels) { $videoModel in
                                    TrackRowView(fileModel: fileModel, videoModel: videoModel, appState: appState).onAppear {
                                        trackPosStart = gr.frame(in: .global).minX
                                        Logger.info(trackPosStart)
                                    }
                                }
                                TrackTimeMarkings(fileModel: fileModel, gr: gr, trackZoomFactor: trackZoomFactor)
                            }.frame(width: gr.size.width * trackZoomFactor).overlay(alignment: .leading) {
                                TrackSnapOverlay(gr: gr, fileModel: fileModel, trackZoomFactor: trackZoomFactor)
                            }
                        }.frame(width: gr.size.width).scrollIndicators(.visible, axes: .horizontal)
                    }
                }
            }
            GridRow {
                overlayButtons
            }
        }
    }

    var overlayButtons: some View {
        VStack {
            HStack {
                Spacer()
                Button("Snap Region") {
                    appState.fileController?.activeFileModel.snapToRegion()
                }.disabled(!videoLoaded)
                Button("Clear Region") {
                    appState.fileController?.activeFileModel.clearRegion()
                }.disabled(!videoLoaded)
                Button(allTracksLocked ? "Unlock All" : "Lock All") {
                    // TODO: Implement track locking.
                    if !allTracksLocked {
                        appState.fileController?.activeFileModel.lockVideos()
                        allTracksLocked = true
                    } else {
                        appState.fileController?.activeFileModel.unlockVideos()
                        allTracksLocked = false
                    }
                }.disabled(!videoLoaded)

                Slider(value: $trackZoomFactor, in: 1 ... 3) {
                    Button {
                        trackZoomFactor = 1
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                } minimumValueLabel: {
                    Text("1x")
                } maximumValueLabel: {
                    Text("3x")
                }.frame(width: 200).disabled(!videoLoaded)
            }
            HStack(alignment: .bottom) {
                Spacer()
                Button(appState.highlightMode ? "Enable Cell Highlighting" : "Disable Cell Highlighting") {
                    // TODO: highlight and focus
                    appState.toggleHighlightMode()
                }.disabled(!videoLoaded)
                Button(appState.focusMode ? "Enable Highlight + Focus" : "Disable Highlight + Focus") {
                    // TODO: highlight and focus
                    appState.toggleFocusMode()
                }.disabled(!videoLoaded)
                Button("Sync Videos", action: syncVideos).disabled(!videoLoaded || allTracksLocked)
                Button("Add Video", action: {
                    addVideo()
                })
            }
        }.onChange(of: appState.fileController?.activeFileModel) { _ in
            if appState.fileController?.activeFileModel.videoModels.count ?? 0 > 0 {
                videoLoaded = true
            }
        }
    }
}
