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
    let player: AVPlayer
    @ObservedObject var videoModel: VideoModel

    var body: some View {
        VStack {
            VideoPlayer(player: player)
                .onAppear {
                    player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.01, preferredTimescale: 600), queue: nil) { time in
                        // update videoPos with the new video time (as a percentage)
                        $videoModel.currentTime.wrappedValue = time.seconds
                        $videoModel.currentPos.wrappedValue = time.seconds / player.getCurrentTrackDuration()
                        print($videoModel.currentPos)
                    }
                }
            TracksStackView(videoModel: videoModel)
        }
    }
}

struct VideoView_Previews: PreviewProvider {
    static var previews: some View {
        let player = AVPlayer(url: Bundle.main.url(forResource: "IMG_1234", withExtension: "MOV")!)
        let vm = VideoModel(videoFilePath: "IMG_1234")
        VideoView(player: player, videoModel: vm)
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
