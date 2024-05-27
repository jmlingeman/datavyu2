//
//  TimeHelpers.swift
//  datavyu
//
//  Created by Jesse Lingeman on 7/8/23.
//

import Foundation

func formatTimestamp(timestamp: Int) -> String {
    let hours = Int(floor(Double(timestamp / 1000 / 3600)))
    let minutes = Int(floor(Double(timestamp / 1000 % 3600 / 60)))
    let seconds = Int(floor(Double(timestamp / 1000 % 60)))
    let milliseconds = timestamp % 1000

    return "\(hours):\(minutes):\(seconds):\(milliseconds)"
}

func timestringToTimestamp(timestring: String) -> Int {
    if timestring.contains(":") {
        let clock = timestring.split(separator: ":")
        let hours = Int(clock[0]) ?? 0
        var minutes = 0
        if clock.count >= 2 {
            minutes = Int(clock[1]) ?? 0
        }
        var seconds = 0
        if clock.count >= 3 {
            seconds = Int(clock[2]) ?? 0
        }
        var milliseconds = 0
        if clock.count >= 4 {
            milliseconds = Int(clock[3]) ?? 0
        }

        return (hours * 1000 * 60 * 60) + (minutes * 1000 * 60) + (seconds * 1000) + milliseconds
    } else {
        // Its an integer, so treat it like one
        let t: Int? = Int(timestring)
        return t ?? 0
    }
}

func timestringToSecondsDouble(timestring: String) -> Double {
    return Double(timestringToTimestamp(timestring: timestring)) / 1000.0
}

func millisToDouble(millis: Int) -> Double {
    return Double(millis) / 1000.0
}
