//
//  VideoView.swift
//  sheettest
//
//  Created by Jesse Lingeman on 6/2/23.
//

import AVKit
import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI

struct VideoView: View {
    @ObservedObject var videoModel: VideoModel

    var body: some View {
        VStack {
            VideoPlayer(player: videoModel.player)
                .onAppear {
                    videoModel.player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.01, preferredTimescale: 600), queue: nil) { time in
                        // update videoPos with the new video time (as a percentage)
                        $videoModel.currentTime.wrappedValue = time.seconds
                        $videoModel.currentPos.wrappedValue = time.seconds / videoModel.player.getCurrentTrackDuration()
                    }
                }
            TracksStackView(videoModel: videoModel)
        }
    }
}

struct VideoView_Previews: PreviewProvider {
    static var previews: some View {
        let vm = VideoModel(videoFilePath: "IMG_1234")
        VideoView(videoModel: vm)
    }
}

extension AVPlayer {
    func getCurrentTrackDuration () -> Float64 {
        guard let currentItem = self.currentItem else { return 0.0 }
        guard currentItem.loadedTimeRanges.count > 0 else { return 0.0 }
        
        let timeInSecond = CMTimeGetSeconds((currentItem.loadedTimeRanges[0].timeRangeValue).duration);
        
        return timeInSecond >= 0.0 ? timeInSecond : 0.0
    }
}
