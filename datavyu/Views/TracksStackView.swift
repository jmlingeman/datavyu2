

import SwiftUI
import UniformTypeIdentifiers

struct TracksStackView: View {
    @ObservedObject var fileModel: FileModel

    func syncVideos() {
        if fileModel.videoModels.count > 1 && fileModel.videoModels[0].selectedMarker != nil {
            fileModel.videoModels[0].syncMarker = fileModel.videoModels[0].selectedMarker
            fileModel.primaryMarker = fileModel.videoModels[0].syncMarker
            for videoModel in fileModel.videoModels[1...] {
                let time = videoModel.selectedMarker?.time
                if time != nil {
                    videoModel.syncMarker = videoModel.selectedMarker
                    videoModel.syncOffset = videoModel.syncMarker!.time - fileModel.primaryMarker!.time
                }
            }
            fileModel.seekAllVideos(to: fileModel.primaryMarker!.time)
        }
    }
    
    func addVideo() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.video, .quickTimeMovie, .mpeg]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK {
            fileModel.addVideo(videoUrl: panel.url!)
            fileModel.updates += 1
        }
    }
    
    func getTrackWidthProportion(videoModel: VideoModel) -> Double {
        return videoModel.duration / fileModel.longestDuration
    }

    var body: some View {
        VStack {
            HStack {
                VStack {
                    ForEach(fileModel.videoModels) { videoModel in
                        HStack {
                            Text(videoModel.videoFilePath.lastPathComponent)
                        }.frame(height: 30)
                    }
                }
                GeometryReader { gr in
                    VStack {
                        ForEach(fileModel.videoModels) { videoModel in
                            HStack {
                                
                                TrackView(videoModel: videoModel,
                                          fileModel: fileModel,
                                          primaryMarker: $fileModel.primaryMarker
                                )
                                .onTapGesture {
                                    fileModel.updates += 1
                                    videoModel.updates += 1
                                }
                                // TODO Fix this up
//                                .frame(width: gr.size.width * getTrackWidthProportion(videoModel: videoModel))
                            }.frame(height: 30)
                        }
                    }.overlay {
                        if fileModel.videoModels.count > 0 {
                            TrackPositionIndicator(fileModel: fileModel, videoModel: fileModel.videoModels[0], gr: gr)
                        }
                    }
                }
            }
                
            ForEach(fileModel.videoModels) { videoModel in
                ClockView(videoModel: videoModel)
            }
        }.frame(height: 100).overlay(alignment: .bottomTrailing) {
            overlayButtons
        }
    }

    var overlayButtons: some View {
        HStack(alignment: .bottom) {
            Spacer()
            Button("Sync Videos", action: syncVideos)
            Button("Add Video", action: addVideo)
        }
    }
}

// struct TracksStackView_Previews: PreviewProvider {
//    static var previews: some View {
//        TracksStackView(videoModels: [VideoModel(videoFilePath: "IMG_1234")])
//    }
// }
