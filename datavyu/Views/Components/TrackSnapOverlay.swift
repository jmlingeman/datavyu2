//
//  TrackSnapOverlay.swift
//  Datavyu2
//
//  Created by Jesse Lingeman on 6/27/24.
//

import SwiftUI

struct TrackSnapOverlay: View {
    var gr: GeometryProxy
    var fileModel: FileModel
    var trackZoomFactor: CGFloat
//    @Binding var trackPosStart: CGFloat

    @State var leftRegionProp: CGFloat = -0.005
    @State var rightRegionProp: CGFloat = 1.001

    let leftOffset: CGFloat = 290
    let leftTrackStart: CGFloat = 295

    let rightGutterSize: CGFloat = 10
    @State var rightTrackEnd: CGFloat = 0

    func getProportion(xpos: CGFloat) -> CGFloat {
        (xpos - leftTrackStart) / (rightTrackEnd - leftTrackStart)
    }

    func leftDragGesture(gesture: DragGesture.Value) {
        if fileModel.primaryVideo != nil {
            if gesture.location.x >= leftOffset {
                leftRegionProp = min(getProportion(xpos: gesture.location.x), 1.0)
                if leftRegionProp >= rightRegionProp {
                    leftRegionProp = rightRegionProp
                }
            }
        }
    }

    func rightDragGesture(gesture: DragGesture.Value) {
        if fileModel.primaryVideo != nil {
            if gesture.location.x <= rightTrackEnd + rightGutterSize {
                rightRegionProp = max(getProportion(xpos: gesture.location.x), 0.0)
                if rightRegionProp <= leftRegionProp {
                    rightRegionProp = leftRegionProp
                }
            }
        }
    }

    var body: some View {
        Rectangle().frame(width: 8, height: .infinity, alignment: .trailing)
            .background(Color.green)
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .position(x: leftRegionProp * ((gr.size.width * trackZoomFactor - rightGutterSize) - leftTrackStart - rightGutterSize) + leftOffset + (leftTrackStart - leftOffset), y: gr.size.height / 2)
            .opacity(0.5)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        leftDragGesture(gesture: gesture)
                    }
                    .onEnded { gesture in
                        leftDragGesture(gesture: gesture)
                    }
            ).onChange(of: fileModel.leftRegionTime) { _ in
                if fileModel.primaryVideo != nil {
                    // TODO: Set the position if some other part of the program changed it
                }
            }.onChange(of: leftRegionProp) { newValue in
                Logger.info(newValue)
                if newValue >= 0, newValue < 1 {
                    let absoluteTime = fileModel.primaryVideo!.getDuration() * newValue
                    Logger.info(absoluteTime)
                    fileModel.leftRegionTime = absoluteTime
                }
            }
        Rectangle().frame(width: 8, height: .infinity, alignment: .leading)
            .background(Color.green)
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .position(x: rightRegionProp * ((gr.size.width * trackZoomFactor - rightGutterSize) - leftTrackStart - rightGutterSize) + leftOffset + (leftTrackStart - leftOffset), y: gr.size.height / 2) // TODO: Fix this so its not based on a magic value. Gotta put into the same ref frame.
            .offset(x: 15)
            .opacity(0.5)
            .onAppear {
                rightTrackEnd = gr.size.width * trackZoomFactor - rightGutterSize
            }.gesture(
                DragGesture()
                    .onChanged { gesture in
                        rightDragGesture(gesture: gesture)
                    }
                    .onEnded { gesture in
                        rightDragGesture(gesture: gesture)
                    }
            ).onChange(of: fileModel.rightRegionTime) { newValue in
                if fileModel.primaryVideo != nil {
                    // TODO: Set the position if some other part of the program changed it
                    rightRegionProp = newValue / fileModel.primaryVideo!.getDuration()
                }
            }.onChange(of: fileModel.leftRegionTime) { newValue in
                if fileModel.primaryVideo != nil {
                    // TODO: Set the position if some other part of the program changed it
                    leftRegionProp = newValue / fileModel.primaryVideo!.getDuration()
                }
            }.onChange(of: rightRegionProp) { newValue in
                if newValue >= 0, newValue < 1 {
                    let absoluteTime = fileModel.primaryVideo!.getDuration() * newValue
                    Logger.info(absoluteTime)
                    fileModel.rightRegionTime = absoluteTime

                    if fileModel.primaryVideo!.currentTime > absoluteTime {
                        fileModel.seekAllVideos(to: absoluteTime)
                    }
                }
            }.onChange(of: leftRegionProp) { newValue in
                if newValue >= 0, newValue < 1 {
                    let absoluteTime = fileModel.primaryVideo!.getDuration() * newValue
                    Logger.info(absoluteTime)
                    fileModel.leftRegionTime = absoluteTime

                    if fileModel.primaryVideo!.currentTime < absoluteTime {
                        fileModel.seekAllVideos(to: absoluteTime)
                    }
                }
            }
    }
}
