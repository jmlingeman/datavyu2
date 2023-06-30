//
//  ArgumentModel.swift
//  sheettest
//
//  Created by Jesse Lingeman on 6/2/23.
//

import Foundation

class Argument: ObservableObject, Identifiable {
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
