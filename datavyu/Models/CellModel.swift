//
//  Cell.swift
//  sheettest
//
//  Created by Jesse Lingeman on 6/2/23.
//

import Foundation

class CellModel: ObservableObject, Identifiable, Equatable, Hashable {

    @Published var column: ColumnModel
    @Published var onset: Int = 0
    @Published var offset: Int = 0
    @Published var ordinal: Int = 0
    @Published var comment: String = ""
    @Published var arguments: [Argument] = [Argument(name: "test1", value: "a"), Argument(name: "test2", value: "b")]
    @Published var onsetPosition: Double = 0
    @Published var offsetPosition: Double = 0
        
    init(column: ColumnModel) {
        self.column = column
    }

    func setOnset(onset: Double) {
        self.onset = Int(onset * 1000)
    }
    
    func setOnset(onset: String) {
        self.onset = timestringToTimestamp(timestring: onset)
    }
    
    func setOffset(offset: String) {
        self.offset = timestringToTimestamp(timestring: offset)
    }

    func setOffset(offset: Double) {
        self.offset = Int(offset * 1000)
    }
    
    func setArgumentValue(index: Int, value: String) {
        arguments[index].value = value
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
        let minutes = Int(clock[1]) ?? 0
        let seconds = Int(clock[2]) ?? 0
        let milliseconds = Int(clock[3]) ?? 0

        return (hours * 1000 * 60 * 60) + (minutes * 1000 * 60) + (seconds * 1000) + milliseconds
    }
    
    static func == (lhs: CellModel, rhs: CellModel) -> Bool {
        if lhs.id == rhs.id {
            return true
        }
        return false
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(onset)
        hasher.combine(offset)
        hasher.combine(id)
    }
}
