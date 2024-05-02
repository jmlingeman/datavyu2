//
//  Cell.swift
//  sheettest
//
//  Created by Jesse Lingeman on 6/2/23.
//

import Foundation
import Vapor

final class CellModel: ObservableObject, Identifiable, Equatable, Hashable, Codable, Content, Comparable {
        
    @Published var column: ColumnModel
    @Published var onset: Int = 0
    @Published var offset: Int = 0
    @Published var ordinal: Int = 0
    @Published var comment: String = ""
    @Published var arguments: [Argument] = []
    @Published var onsetPosition: Double = 0
    @Published var offsetPosition: Double = 0
        
    init() {
        self.column = ColumnModel(sheetModel: SheetModel(sheetName: "dummy"), columnName: "dummy")
        syncArguments()
    }
    
    init(column: ColumnModel) {
        self.column = column
        syncArguments()
    }
    
    static func == (lhs: CellModel, rhs: CellModel) -> Bool {
        return lhs.onset == rhs.onset && lhs.offset == rhs.offset && lhs.arguments == rhs.arguments && lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(onset)
        hasher.combine(offset)
        hasher.combine(arguments)
        hasher.combine(id)
    }
    
    static func < (lhs: CellModel, rhs: CellModel) -> Bool {
        if lhs.onset == rhs.onset {
            return lhs.offset < rhs.offset
        } else {
            return lhs.onset < rhs.onset
        }
    }
    
    func syncArguments() {
        let args = column.arguments
        for arg in args {
            var found = false
            for x in self.arguments {
                if arg.name == x.name {
                    found = true
                }
            }
            if !found {
                self.arguments.append(Argument(name: arg.name, column: arg.column))
            }
        }
        self.arguments.last?.isLastArgument = true
    }
    
    func setOnset(onset: Int) {
        print(#function)
        if onset != self.onset {
            DispatchQueue.main.async {
                self.onset = onset
                self.updateSheet()
            }
        }
    }
    
    func updateSheet() {
        self.column.sheetModel.updates += 1
    }

    func setOnset(onset: Double) {
        print(#function)
        self.onset = Int(onset * 1000)
        updateSheet()
    }
    
    func setOnset(onset: String) {
        print(#function)
        self.onset = timestringToTimestamp(timestring: onset)
        updateSheet()
    }
    
    func setOffset(offset: String) {
        print(#function)
        self.offset = timestringToTimestamp(timestring: offset)
        updateSheet()
    }
    
    func setOffset(offset: Int) {
        print(#function)
        if offset != self.offset {
            DispatchQueue.main.async {
                self.offset = offset
                self.updateSheet()
            }
        }
    }

    func setOffset(offset: Double) {
        self.offset = Int(offset * 1000)
        updateSheet()
    }
    
    func setArgumentValue(index: Int, value: String) {
        arguments[index].value = value
        updateSheet()
    }
    
//    static func == (lhs: CellModel, rhs: CellModel) -> Bool {
//        if lhs.id == rhs.id {
//            return true
//        }
//        return false
//    }
    
    
    
    enum CodingKeys: CodingKey {
        case onset
        case offset
        case comment
        case arguments
        case column
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        onset = try container.decode(Int.self, forKey: .onset)
        offset = try container.decode(Int.self, forKey: .offset)
        comment = try container.decode(String.self, forKey: .comment)
        arguments = try container.decode(Array<Argument>.self, forKey: .arguments)
        column = try container.decode(ColumnModel.self, forKey: .column)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(onset, forKey: .onset)
        try container.encode(offset, forKey: .offset)
        try container.encode(comment, forKey: .comment)
        try container.encode(arguments, forKey: .arguments)
        try container.encode(column, forKey: .column)
    }
}
