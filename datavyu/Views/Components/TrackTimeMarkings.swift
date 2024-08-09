//
//  TrackTimeMarkings.swift
//  Datavyu2
//
//  Created by Jesse Lingeman on 7/3/24.
//

import SwiftUI

enum TimeCodeLevel {
    case seconds
    case minutes
    case hours
}

struct TrackTimeMarkings: View {
    @ObservedObject var fileModel: FileModel
    var gr: GeometryProxy
    var trackZoomFactor: CGFloat

    let leftTrackStart: CGFloat = 305
    let rightTrackEnd: CGFloat = 10

    func calculateTimeFromPos(x: Double, gr: GeometryProxy) -> Double {
        let duration = fileModel.longestDuration
        let trackLength = (gr.size.width * trackZoomFactor - leftTrackStart - rightTrackEnd)
        let time = (x - leftTrackStart) / trackLength * duration

        return time
    }

    func getLinePositions(duration: Double, gr: GeometryProxy, timeLevel: TimeCodeLevel) -> [Double] {
        var lines: [Double] = []
        var numLines = 0
        var cutoff = 0

        switch timeLevel {
        case .seconds:
            numLines = Int(duration)
            cutoff = Int(duration)
        case .minutes:
            numLines = Int(duration / 60)
            cutoff = Int(duration / 60) * 60
        case .hours:
            numLines = Int(duration / 60 / 60)
            cutoff = Int(duration / 60 / 60) * 60 * 60
        }

        if numLines > 100 {
            if timeLevel == .seconds {
                numLines = Int(duration / 60) * 2
            } else if timeLevel == .minutes {
                numLines = Int(duration / 60 / 60) * 2
            }
        }

        // Get the percentage of the duration with the last bit that this time level won't cover cut off
        let coveredProp = Double(cutoff) / duration
        let stepWidth = (gr.size.width * trackZoomFactor - leftTrackStart - rightTrackEnd) * coveredProp / Double(numLines)

        for i in 0 ... numLines {
            let linePos = Double(i) * stepWidth
            lines.append(linePos)
        }

        return lines
    }

    var body: some View {
        ZStack {
            Rectangle().frame(width: gr.size.width * trackZoomFactor - leftTrackStart - rightTrackEnd, height: 20).position(x: leftTrackStart + (gr.size.width * trackZoomFactor - leftTrackStart - rightTrackEnd) / 2).foregroundColor(Color(NSColor.controlBackgroundColor))
            ForEach(getLinePositions(duration: fileModel.longestDuration, gr: gr, timeLevel: .seconds), id: \.self) { linePos in
                Rectangle().frame(width: 1, height: 10).position(x: linePos + leftTrackStart).foregroundColor(Color.blue)
            }
            ForEach(getLinePositions(duration: fileModel.longestDuration, gr: gr, timeLevel: .minutes), id: \.self) { linePos in
                Rectangle().frame(width: 1, height: 15).position(x: linePos + leftTrackStart).foregroundColor(Color.green)
            }
            ForEach(getLinePositions(duration: fileModel.longestDuration, gr: gr, timeLevel: .hours), id: \.self) { linePos in
                Rectangle().frame(width: 1, height: 20).position(x: linePos + leftTrackStart).foregroundColor(Color.red)
            }
        }.onTapGesture { location in
            fileModel.seekAllVideos(to: calculateTimeFromPos(x: location.x, gr: gr))
        }
    }
}
