//
//  TrackView.swift
//  datavyu
//
//  Created by Jesse Lingeman on 6/18/23.
//

import SwiftUI

struct TrackView: View {
    @ObservedObject var videoModel: VideoModel
    @ObservedObject var fileModel: FileModel
    @Binding var primaryMarker: Marker?
    @State var selectedMarker: Marker?

    func addMarker() {
        videoModel.addMarker(time: videoModel.currentTime)
    }
    
    func deleteMarker() {
        if selectedMarker != nil {
            videoModel.deleteMarker(time: selectedMarker!.time)
        }
    }
    
    func removeVideo() {
        fileModel.removeVideoModel(videoModel: videoModel)
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
            .offset(x: alignMarkers(primaryMarker: primaryMarker, secondaryMarker: videoModel.syncMarker, width: gr.size.width))
        }
    }
    
    func alignMarkers(primaryMarker: Marker?, secondaryMarker: Marker?, width: Double) -> Double {
        print("Markers: \(primaryMarker != nil) \(secondaryMarker != nil)")
        if primaryMarker == nil || secondaryMarker == nil {
            return 0
        }
        
        // Get marker proportions
        let priX = primaryMarker!.time / primaryMarker!.videoDuration * width
        let secX = secondaryMarker!.time / secondaryMarker!.videoDuration * width
        
        print("Marker calc: \(secX) - \(priX) = \(secX-priX)")
        
        return -(secX - priX)
    }


    var trackOverlay: some View {
        HStack(alignment: .bottom) {
            Spacer()
            Button("Add Marker", action: addMarker)
            Button("❌", action: removeVideo)
        }
    }
}

//struct TrackView_Previews: PreviewProvider {
//    static var previews: some View {
//        TrackView(videoModel: VideoModel(videoFilePath: "IMG_1234"), primarySyncTime: 0.0)
//    }
//}
