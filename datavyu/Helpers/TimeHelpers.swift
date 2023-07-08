//
//  TimeHelpers.swift
//  datavyu
//
//  Created by Jesse Lingeman on 7/8/23.
//

import Foundation

func formatTimestamp(timestamp: Int) -> String {
    let hours = floor(Double(timestamp / 1000 / 3600))
    let minutes = floor(Double(timestamp / 1000 % 3600 / 60))
    let seconds = floor(Double(timestamp / 1000 % 60))
    let milliseconds = timestamp % 1000
    
    return "\(hours):\(minutes):\(seconds):\(milliseconds)"
}

func timestringToTimestamp(timestring: String) -> Int {
    let clock = timestring.split(separator: ":")
    let hours = Int(clock[0]) ?? 0
    let minutes = Int(clock[1]) ?? 0
    let seconds = Int(clock[2]) ?? 0
    let milliseconds = Int(clock[3]) ?? 0
    
    return (hours * 1000 * 60 * 60) + (minutes * 1000 * 60) + (seconds * 1000) + milliseconds
}
