//
//  ArgumentModel.swift
//  sheettest
//
//  Created by Jesse Lingeman on 6/2/23.
//

import Foundation
import Vapor

final class Argument: ObservableObject, Identifiable, Equatable, Hashable, Codable, Content {
    @Published var name: String
    @Published var value: String
    @Published var column: ColumnModel
    
    @Published var isLastArgument: Bool = false
    var id: UUID = UUID()
    
    static func == (lhs: Argument, rhs: Argument) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    init() {
        self.name = ""
        self.value = ""
        self.column = ColumnModel()
    }
    
    init(name: String, column: ColumnModel) {
        self.name = name
        self.value = ""
        self.column = column
    }
    
    init(name: String, value: String, column: ColumnModel) {
        self.name = name
        self.value = value
        self.column = column
    }
    
    func setValue(value: String) {
        self.value = value
        self.column.sheetModel.updates += 1
    }
    
    func blankCopy() -> Argument {
        return Argument(name: self.name, column: self.column)
    }
    
    enum CodingKeys: CodingKey {
        case name
        case value
        case column
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        value = try container.decode(String.self, forKey: .value)
        column = try container.decode(ColumnModel.self, forKey: .column)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(value, forKey: .value)
        try container.encode(column, forKey: .column)
    }
    
}
