//
//  SpectrogramProgressView.swift
//  datavyu
//
//  Created by Jesse Lingeman on 5/24/24.
//

import SwiftUI

struct SpectrogramProgressView: View {
    let outputPath: URL
    let videoModel: VideoModel
    @Environment(\.dismiss) var dismiss

    
    @StateObject var spectrogramBuilder = SpectrogramVideoBuilder(delegate: nil)
    
    init(outputPath: URL, videoModel: VideoModel) {
        self.outputPath = outputPath
        self.videoModel = videoModel
    }

    var body: some View {
        ProgressView(value: spectrogramBuilder.progress).onAppear {
            DispatchQueue.main.async {
                spectrogramBuilder.build(with: videoModel.player, type: .mov, toOutputPath: outputPath)
            }
        }
        Button {
            dismiss()
        } label: {
            Text("Close")
        }.disabled(!spectrogramBuilder.isFinished)
    }
}
