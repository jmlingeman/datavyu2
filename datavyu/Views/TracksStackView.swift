

import SwiftUI

struct TracksStackView: View {
    @ObservedObject var fileModel: FileModel
    
    func syncVideos() {
        let primaryVideo = fileModel.videoModels[0]
        
        for videoModel in fileModel.videoModels {
            let time = videoModel.selectedMarker?.time
            if time != nil {
                videoModel.syncOffset = time!
            }
        }
    }
    
    
    var body: some View {
        VStack {
            ForEach(fileModel.videoModels) { videoModel in
                HStack {
                    Text(videoModel.videoFilePath)
                    TrackView(videoModel: videoModel).onTapGesture {
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

