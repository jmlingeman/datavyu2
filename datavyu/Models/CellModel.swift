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
    @Published var arguments: [Argument] = [Argument(name: "test1", value: "a"), Argument(name: "test2", value: "b")]
    @Published var onsetPosition: Double = 0
    @Published var offsetPosition: Double = 0
        
//    init() {}
    
    init(column: ColumnModel) {
        self.column = column
    }
    
    static func == (lhs: CellModel, rhs: CellModel) -> Bool {
        return lhs.onset == rhs.onset && lhs.offset == rhs.offset && lhs.arguments == rhs.arguments
    }
    
    static func < (lhs: CellModel, rhs: CellModel) -> Bool {
        if lhs.onset == rhs.onset {
            return lhs.offset < rhs.offset
        } else {
            return lhs.onset < rhs.onset
        }
    }
    
    func setOnset(onset: Int) {
        self.onset = onset
        self.column.sheetModel.updates += 1
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
    
    func setOffset(offset: Int) {
        self.offset = offset
    }

    func setOffset(offset: Double) {
        self.offset = Int(offset * 1000)
    }
    
    func setArgumentValue(index: Int, value: String) {
        arguments[index].value = value
    }
    
//    static func == (lhs: CellModel, rhs: CellModel) -> Bool {
//        if lhs.id == rhs.id {
//            return true
//        }
//        return false
//    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(onset)
        hasher.combine(offset)
        hasher.combine(id)
    }
    
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
