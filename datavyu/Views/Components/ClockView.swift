//
//  ClockView.swift
//  datavyu
//
//  Created by Jesse Lingeman on 6/19/23.
//

import SwiftUI

struct HoursTextStyle: ShapeStyle {
    func resolve(in _: EnvironmentValues) -> some ShapeStyle {
        Color.red
    }
}

struct MinsTextStyle: ShapeStyle {
    func resolve(in _: EnvironmentValues) -> some ShapeStyle {
        Color.green
    }
}

struct SecsTextStyle: ShapeStyle {
    func resolve(in _: EnvironmentValues) -> some ShapeStyle {
        Color.blue
    }
}

struct MillisTextStyle: ShapeStyle {
    func resolve(in _: EnvironmentValues) -> some ShapeStyle {
        Color.gray
    }
}

struct ClockView: View {
    @ObservedObject var videoModel: VideoModel
    var body: some View {
        let time = formatTimestamp(timestampSeconds: $videoModel.currentTime.wrappedValue)
        let splitTime = time.split(separator: ":")
        let hours = splitTime[0]
        let mins = splitTime[1]
        let secs = splitTime[2]
        let millis = splitTime[3]

        Text(hours).foregroundColor(Color.red)
            + Text(":")
            + Text(mins).foregroundColor(Color.green)
            + Text(":")
            + Text(secs).foregroundColor(Color.blue)
            + Text(":") + Text(millis).foregroundColor(Color.gray)
            + Text("@ \(String(format: "%.2f", $videoModel.player.rate.wrappedValue))x")
    }
}
