//
//  VideoView.swift
//  sheettest
//
//  Created by Jesse Lingeman on 6/2/23.
//

import SwiftUI
import AVKit
import CoreImage
import CoreImage.CIFilterBuiltins


struct VideoView: View {
    
    let player: AVPlayer
    @ObservedObject var videoModel: VideoModel
    
    var body: some View {
        VStack{
            VideoPlayer(player: player)
                .onAppear{
                    player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.01, preferredTimescale: 600), queue: nil) { time in
                        // update videoPos with the new video time (as a percentage)
                        $videoModel.currentTime.wrappedValue = time.seconds
                    }
                }
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
