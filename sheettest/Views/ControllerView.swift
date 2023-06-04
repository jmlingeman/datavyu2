//
//  ControllerView.swift
//  sheettest
//
//  Created by Jesse Lingeman on 6/3/23.
//

import SwiftUI
import CoreMedia
import AVKit

struct ControllerView: View {
    
    @StateObject var videoModel = VideoModel(videoFilePath: "IMG_1234")
    @StateObject var sheetModel = SheetModel(sheetName: "IMG_1234")
    let player = AVPlayer(url: Bundle.main.url(forResource: "IMG_1234", withExtension: "MOV")!)
    
    func play() {
        self.player.play()
    }
    
    func stop() {
        self.player.pause()
    }
    
    func nextFrame() {
        self.player.currentItem!.step(byCount: 1)
    }
    
    func prevFrame() {
        self.player.currentItem!.step(byCount: -1)
    }
    
    var body: some View {
        HStack {
            Grid {
                GridRow {
                    VideoView(player: player, videoModel: videoModel)
                }
                GridRow {
                    Text("\($videoModel.currentTime.wrappedValue)")
                }
                GridRow {
                    Button("Play", action: play).keyboardShortcut("p", modifiers: [])
                    Button("Stop", action: stop).keyboardShortcut("s", modifiers: [])
                }
                GridRow {
                    Button("Next", action: nextFrame).keyboardShortcut("w", modifiers: [])
                    Button("Prev", action: prevFrame).keyboardShortcut("q", modifiers: [])
                }
            }
            Sheet(sheetDataModel: sheetModel)
        }
    }
}

struct ControllerView_Previews: PreviewProvider {

    
    static var previews: some View {
        ControllerView()
    }
}
