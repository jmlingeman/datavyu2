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
    
    var body: some View {
        GeometryReader { gr in
            Rectangle().frame(width: 5).foregroundColor(Color.red)
                .position(x: videoModel.currentPos * gr.size.width,
                          y: 15)
                .gesture(
                    DragGesture()
                        .onChanged { gesture in
                            let relativePos = clamp(x: gesture.location.x / gr.size.width, minVal: 0, maxVal: 1)
                            let absoluteTime = fileModel.primaryVideo!.getDuration() * relativePos
                            fileModel.seekAllVideos(to: absoluteTime)
                        }
                        .onEnded { gesture in
                            let relativePos = clamp(x: gesture.location.x / gr.size.width, minVal: 0, maxVal: 1)
                            let absoluteTime = fileModel.primaryVideo!.getDuration() * relativePos
                            fileModel.seekAllVideos(to: absoluteTime)
                        }
                )
                .frame(maxWidth: .infinity)
        }
    }
}
