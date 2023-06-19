//
//  TrackView.swift
//  datavyu
//
//  Created by Jesse Lingeman on 6/18/23.
//

import SwiftUI

struct TrackView: View {
    @ObservedObject var videoModel: VideoModel
    
    var body: some View {
        GeometryReader { gr in
            ZStack {
                Rectangle().frame(maxWidth: .infinity).foregroundColor(Color.blue)
                Rectangle().frame(width: 5).foregroundColor(Color.red)
                    .position(x: $videoModel.currentPos.wrappedValue * gr.size.width, y: gr.size.height / 2)
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                let relativePos = max(min(gesture.location.x / gr.size.width, 1), 0)
                                videoModel.seekPercentage(to: relativePos)
                            }
                            .onEnded { gesture in
                                let relativePos = max(min(gesture.location.x / gr.size.width, 1), 0)
                                videoModel.seekPercentage(to: relativePos)
                            }
                    )
            }
        }
    }
}

struct TrackView_Previews: PreviewProvider {
    static var previews: some View {
        TrackView(videoModel: VideoModel(videoFilePath: "IMG_1234"))
    }
}
