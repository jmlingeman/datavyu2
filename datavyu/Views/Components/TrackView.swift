//
//  TrackView.swift
//  datavyu
//
//  Created by Jesse Lingeman on 6/18/23.
//

import DSWaveformImage
import DSWaveformImageViews
import SwiftUI

struct TrackView: View {
    @ObservedObject var videoModel: VideoModel
    @ObservedObject var fileModel: FileModel
    @Binding var primaryMarker: Marker?
    @State var selectedMarker: Marker?
    @State var calcWidth: Double = 0

    @State var configuration: Waveform.Configuration = .init(
        style: .outlined(.blue, 3),
        verticalScalingFactor: 1.0
    )

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
            let calcWidth = gr.size.width * (fileModel.longestDuration > 0 ? (videoModel.duration / fileModel.longestDuration) : 1) + 1
            HStack {
                ZStack {
                    Rectangle().frame(maxWidth: .infinity).foregroundColor(Color.blue)
                    WaveformViewDV(audioURL: videoModel.videoFileURL, videoModel: videoModel, fileModel: fileModel, geometryReader: gr, configuration: configuration).frame(maxWidth: .infinity)
                    ForEach(videoModel.markers) { marker in
                        Rectangle().frame(width: 5).foregroundColor(marker == selectedMarker ? Color.purple : Color.green)
                            .position(x: marker.time / videoModel.getDuration() * calcWidth,
                                      y: gr.size.height / 2).onTapGesture {
                                if selectedMarker == marker {
                                    selectedMarker = nil
                                    videoModel.selectedMarker = nil
                                } else {
                                    selectedMarker = marker
                                    videoModel.selectedMarker = marker
                                }
                            }
                    }
                }
                .frame(width: calcWidth)
                .offset(x: alignMarkers(primaryMarker: fileModel.primaryMarker, secondaryMarker: videoModel.syncMarker, primaryWidth: gr.size.width, secondaryWidth: calcWidth))
                Spacer()
            }.frame(width: gr.size.width).overlay(alignment: .bottomTrailing) {
                trackOverlay
            }
        }
    }

    func alignMarkers(primaryMarker: Marker?, secondaryMarker: Marker?, primaryWidth: Double, secondaryWidth: Double) -> Double {
        if primaryMarker == nil || secondaryMarker == nil {
            return 0
        }
        // Get marker proportions
        let priX = primaryMarker!.time / primaryMarker!.videoDuration * primaryWidth
        let secX = secondaryMarker!.time / secondaryMarker!.videoDuration * secondaryWidth
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

// struct TrackView_Previews: PreviewProvider {
//    static var previews: some View {
//        TrackView(videoModel: VideoModel(videoFilePath: "IMG_1234"), primarySyncTime: 0.0)
//    }
// }
