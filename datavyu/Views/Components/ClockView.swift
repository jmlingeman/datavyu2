//
//  ClockView.swift
//  datavyu
//
//  Created by Jesse Lingeman on 6/19/23.
//

import SwiftUI

struct ClockView: View {
    @ObservedObject var videoModel: VideoModel
    var body: some View {
        GridRow {
            Text("\($videoModel.currentTime.wrappedValue) @ \($videoModel.player.rate.wrappedValue)")
        }
    }
}

struct ClockView_Previews: PreviewProvider {
    static var previews: some View {
        let videoModel = VideoModel(videoFilePath: URL(fileURLWithPath: "/Users/jesse/Downloads/IMG_0822.MOV"))
        ClockView(videoModel: videoModel)
    }
}
