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
        ZStack {
            AVPlayerControllerRepresented(player: videoModel.player)
                .onAppear {
                    videoModel.player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.01, preferredTimescale: 600), queue: nil) { time in
                        $videoModel.currentTime.wrappedValue = time.seconds
                        $videoModel.currentPos.wrappedValue = time.seconds / videoModel.player.getCurrentTrackDuration()
                    }
                }
                .frame(minWidth: 250,
                       idealWidth: videoModel.player.currentItem?.presentationSize.width ?? 250,
                       maxWidth: .infinity,
                       minHeight: 250,
                       idealHeight: videoModel.player.currentItem?.presentationSize.height ?? 250,
                       maxHeight: .infinity,
                       alignment: .center)

//            Button("Open in Window") {
//                self.openInWindow(title: "Win View", sender: self)
//            }
        }
    }
}

struct AVPlayerControllerRepresented: NSViewRepresentable {
    var player: AVPlayer

    func makeNSView(context _: Context) -> AVPlayerView {
        let view = AVPlayerView()
        view.controlsStyle = .none
        view.player = player
        return view
    }

    func updateNSView(_: AVPlayerView, context _: Context) {}
}
