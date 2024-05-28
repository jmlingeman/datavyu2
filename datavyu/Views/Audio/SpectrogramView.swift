//
//  SpectrogramView.swift
//  datavyu
//
//  Created by Jesse Lingeman on 5/15/24.
//

import SwiftUI

struct SpectrogramView: View {
    @ObservedObject var videoModel: VideoModel
    @StateObject private var spectrogramController: SpectrogramController
    
    init(videoModel: VideoModel) {
        self.videoModel = videoModel
        _spectrogramController = StateObject(wrappedValue: SpectrogramController(player: videoModel.player))
    }
    
    var body: some View {
        ZStack {
            Text("\(spectrogramController.updates)")
            Image(nsImage: spectrogramController.outputImage)
                .frame(width: 500, height: 500)
        }
    }
}
