

import SwiftUI

struct TracksStackView: View {
    @ObservedObject var videoModel: VideoModel
    
    var body: some View {
        VStack {
            HStack {
                Text(videoModel.videoFilePath)
                TrackView(videoModel: videoModel)
            }
        }.frame(height: 100)
    }
}

struct TracksStackView_Previews: PreviewProvider {
    static var previews: some View {
        TracksStackView(videoModel: VideoModel(videoFilePath: "IMG_1234"))
    }
}
