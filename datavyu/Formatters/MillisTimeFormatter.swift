//
//  MillisTimeFormatter.swift
//  datavyu
//
//  Created by Jesse Lingeman on 6/10/23.
//

import Foundation

class MillisTimeFormatter: Formatter {
    override func string(for obj: Any?) -> String? {
        if let timeInt = obj as? Int {
            return formatTimestamp(timestamp: timeInt)
        }
        else {
            return "00:00:00:000"
        }
        
    }
    
    override func getObjectValue(
        _ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?,
        for string: String,
        errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?
    ) -> Bool {
        let val = timestringToTimestamp(timestring: string) as AnyObject
        print("saving: \(val)")
        obj?.pointee = val
        return true
    }
    
    func formatTimestamp(timestamp: Int) -> String {
        let hours = Int(floor(Double(timestamp / 1000 / 3600)))
        let minutes = Int(floor(Double(timestamp / 1000 % 3600 / 60)))
        let seconds = Int(floor(Double(timestamp / 1000 % 60)))
        let milliseconds = timestamp % 1000
        
        return "\(String(format: "%02d", hours)):\(String(format: "%02d", minutes)):\(String(format: "%02d", seconds)):\(String(format: "%03d", milliseconds))"
    }
    
    func timestringToTimestamp(timestring: String) -> Int {
        let clock = timestring.split(separator: ":")
        let hours = Int(clock[0]) ?? 0
        let minutes = Int(clock[1]) ?? 0
        let seconds = Int(clock[2]) ?? 0
        let milliseconds = Int(clock[3]) ?? 0
        
        let timeInMillis = (hours * 1000 * 60 * 60) + (minutes * 1000 * 60) + (seconds * 1000) + milliseconds
        print(timeInMillis)
        return timeInMillis
    }
}
