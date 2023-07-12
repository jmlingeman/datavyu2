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
    
    static func == (lhs: Argument, rhs: Argument) -> Bool {
        lhs.name == rhs.name && lhs.value == rhs.value
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(value)
        hasher.combine(id)
    }
    
    init(name: String) {
        self.name = name
        self.value = ""
    }
    
    init(name: String, value: String) {
        self.name = name
        self.value = value
    }
    
    enum CodingKeys: CodingKey {
        case name
        case value
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        value = try container.decode(String.self, forKey: .value)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(value, forKey: .value)
    }


    
}
