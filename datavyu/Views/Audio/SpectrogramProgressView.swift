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
    let fileModel: FileModel
    @Environment(\.dismiss) var dismiss

    @StateObject var spectrogramBuilder = SpectrogramVideoBuilder(delegate: nil)

    init(outputPath: URL, videoModel: VideoModel, fileModel: FileModel) {
        self.outputPath = outputPath
        self.videoModel = videoModel
        self.fileModel = fileModel
    }

    var body: some View {
        ProgressView(value: spectrogramBuilder.progress).onAppear {
            DispatchQueue.main.async {
                spectrogramBuilder.build(with: videoModel.player, type: .mov, toOutputPath: outputPath)
            }
        }
        Button {
            fileModel.addVideo(videoUrl: outputPath)
            dismiss()
        } label: {
            Text("Add to Project and Close")
        }.disabled(!spectrogramBuilder.isFinished)
    }
}
