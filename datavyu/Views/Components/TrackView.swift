//
//  TrackView.swift
//  datavyu
//
//  Created by Jesse Lingeman on 6/18/23.
//

import SwiftUI

struct TrackView: View {
    @ObservedObject var videoModel: VideoModel

    func addMarker() {
        videoModel.addMarker(time: videoModel.currentTime)
    }

    var body: some View {
        GeometryReader { gr in
            ZStack {
                Rectangle().frame(maxWidth: .infinity).foregroundColor(Color.blue)
                Rectangle().frame(width: 5).foregroundColor(Color.red)
                    .position(x: $videoModel.currentPos.wrappedValue * gr.size.width,
                              y: gr.size.height / 2
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                let relativePos = clamp(x: gesture.location.x / gr.size.width, minVal: 0, maxVal: 1)
                                videoModel.seekPercentage(to: relativePos)
                            }
                            .onEnded { gesture in
                                let relativePos = clamp(x: gesture.location.x / gr.size.width, minVal: 0, maxVal: 1)
                                videoModel.seekPercentage(to: relativePos)
                            }
                    )
                ForEach(videoModel.markers) { marker in
                    Rectangle().frame(width: 5).foregroundColor(Color.green)
                        .position(x: marker.time / videoModel.getDuration() * gr.size.width,
                                  y: gr.size.height / 2
                        )
                }
            }.overlay(alignment: .bottomTrailing) {
                trackOverlay
            }
        }
    }

    var trackOverlay: some View {
        HStack(alignment: .bottom) {
            Spacer()
            Button("Add Marker", action: addMarker)
        }
    }
}

struct TrackView_Previews: PreviewProvider {
    static var previews: some View {
        TrackView(videoModel: VideoModel(videoFilePath: "IMG_1234"))
    }
}
