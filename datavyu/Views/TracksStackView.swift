

import SwiftUI

struct TracksStackView: View {
    @ObservedObject var fileModel: FileModel
    
    func syncVideos() {
        if fileModel.videoModels[0].selectedMarker != nil {
            fileModel.videoModels[0].syncMarker = fileModel.videoModels[0].selectedMarker
            fileModel.primarySyncTime = fileModel.videoModels[0].syncMarker!.time
            for videoModel in fileModel.videoModels[1...] {
                let time = videoModel.selectedMarker?.time
                if time != nil {
                    videoModel.syncOffset = time!
                }
            }
        }
    }
    
    
    var body: some View {

        VStack {
            ForEach(fileModel.videoModels) { videoModel in
                let primaryVideoSyncMarkerTime = fileModel.videoModels.count > 0 ? fileModel.videoModels[0].selectedMarker?.time ?? 0.0 : 0.0

                HStack {
                    Text(videoModel.videoFilePath)
                    TrackView(videoModel: videoModel, primarySyncTime: fileModel.primarySyncTime).onTapGesture {
                        fileModel.updates += 1
                        videoModel.updates += 1
                    }
                }
            }
            ForEach(fileModel.videoModels) { videoModel in
                ClockView(videoModel: videoModel)
            }
        }.frame(height: 100).overlay(alignment: .bottomTrailing) {
            syncButton
        }
    }
    
    var syncButton: some View {
        HStack(alignment: .bottom) {
            Spacer()
            Button("Sync Videos", action: syncVideos)
        }
    }
}

//struct TracksStackView_Previews: PreviewProvider {
//    static var previews: some View {
//        TracksStackView(videoModels: [VideoModel(videoFilePath: "IMG_1234")])
//    }
//}

