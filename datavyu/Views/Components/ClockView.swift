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
            Text("\($videoModel.currentTime.wrappedValue)")
        }
    }
}

struct ClockView_Previews: PreviewProvider {
    static var previews: some View {
        let videoModel = VideoModel(videoFilePath: "IMG_1234")
        ClockView(videoModel: videoModel)
    }
}
