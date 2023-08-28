//
//  TrackPositionIndicator.swift
//  datavyu
//
//  Created by Jesse Lingeman on 6/29/23.
//

import SwiftUI

struct TrackPositionIndicator: View {
    @ObservedObject var fileModel: FileModel
    @ObservedObject var videoModel: VideoModel
    let gr: GeometryProxy
    
    var body: some View {
        Rectangle().frame(width: 5).foregroundColor(Color.red)
            .position(x: videoModel.currentPos * gr.size.width,
                      y: gr.size.height / CGFloat(fileModel.videoModels.count))
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        let relativePos = clamp(x: gesture.location.x / gr.size.width, minVal: 0, maxVal: 1)
                        fileModel.seekAllVideosPercent(to: relativePos)
                    }
                    .onEnded { gesture in
                        let relativePos = clamp(x: gesture.location.x / gr.size.width, minVal: 0, maxVal: 1)
                        fileModel.seekAllVideosPercent(to: relativePos)
                    }
            )
    }
}
