//
//  TrackView.swift
//  datavyu
//
//  Created by Jesse Lingeman on 6/18/23.
//

import SwiftUI

struct TrackView: View {
    @ObservedObject var videoModel: VideoModel
    @State var primarySyncTime: Double
    @State var maxDuration: Double
    @State var selectedMarker: Marker?

    func addMarker() {
        videoModel.addMarker(time: videoModel.currentTime)
    }
    
    func deleteMarker() {
        if selectedMarker != nil {
            videoModel.deleteMarker(time: selectedMarker!.time)
        }
    }

    var body: some View {
        GeometryReader { gr in
            ZStack {
                Rectangle().frame(maxWidth: .infinity).foregroundColor(Color.blue)
                ForEach(videoModel.markers) { marker in
                    Rectangle().frame(width: 5).foregroundColor(marker == selectedMarker ? Color.purple : Color.green)
                        .position(x: marker.time / videoModel.getDuration() * gr.size.width,
                                  y: gr.size.height / 2
                        ).onTapGesture {
                            if selectedMarker == marker {
                                selectedMarker = nil
                                videoModel.selectedMarker = nil
                            } else {
                                selectedMarker = marker
                                videoModel.selectedMarker = marker
                            }
                        }
                }
            }.overlay(alignment: .bottomTrailing) {
                trackOverlay
            }
            .offset(x: videoModel.syncOffset != 0 ? (videoModel.syncOffset - primarySyncTime) * gr.size.width : 0)
        }
    }


    var trackOverlay: some View {
        HStack(alignment: .bottom) {
            Spacer()
            Button("Add Marker", action: addMarker)
        }
    }
}

//struct TrackView_Previews: PreviewProvider {
//    static var previews: some View {
//        TrackView(videoModel: VideoModel(videoFilePath: "IMG_1234"), primarySyncTime: 0.0)
//    }
//}
