//
//  ArgumentModel.swift
//  sheettest
//
//  Created by Jesse Lingeman on 6/2/23.
//

import Foundation

class Argument: ObservableObject, Identifiable, Equatable, Hashable {
    static func == (lhs: Argument, rhs: Argument) -> Bool {
        lhs.name == rhs.name && lhs.value == rhs.value
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(value)
        hasher.combine(id)
    }
    
    @Published var name: String
    @Published var value: String
    
    init(name: String) {
        self.name = name
        self.value = ""
    }
    
    init(name: String, value: String) {
        self.name = name
        self.value = value
    }

}
