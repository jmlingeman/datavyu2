//
//  Cell.swift
//  sheettest
//
//  Created by Jesse Lingeman on 6/2/23.
//

import Foundation
import TimecodeKit


class CellModel: ObservableObject, Identifiable, Equatable, Hashable {
    
    static func == (lhs: CellModel, rhs: CellModel) -> Bool {
        if(lhs.id == rhs.id) {
            return true
        }
        return false
    }
    
    func hash(into hasher: inout Hasher) {
            hasher.combine(onset)
            hasher.combine(offset)
            hasher.combine(id)
        }
    
    @Published var onset: Timecode = try! Timecode(Timecode.Components(h: 00, m: 00, s: 00, f:00), at: ._29_97)
    @Published var offset: Timecode = try! Timecode(Timecode.Components(h: 00, m: 00, s: 00, f:00), at: ._29_97)
    @Published var ordinal: Int = 0
    @Published var comment: String = ""
    @Published var arguments: [Argument] = [Argument(name: "test1", value: "a"), Argument(name: "test2", value: "b")]
    
    func setOnset(onset: Double) {
        self.onset = try! onset.toTimecode(at: ._29_97)
    }
    
    func setOffset(offset: Double) {
        self.offset = try! offset.toTimecode(at: ._29_97)
    }
    
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
        let minutes  = Int(clock[1]) ?? 0
        let seconds = Int(clock[2]) ?? 0
        let milliseconds = Int(clock[3]) ?? 0
        
        return (hours * 1000 * 60 * 60) + (minutes * 1000 * 60) + (seconds * 1000) + milliseconds
    }
    
    
}
