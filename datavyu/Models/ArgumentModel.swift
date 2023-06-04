//
//  ArgumentModel.swift
//  sheettest
//
//  Created by Jesse Lingeman on 6/2/23.
//

import Foundation

class Argument: ObservableObject, Identifiable {
    @Published var value: String = ""
    let name: String

    init(name: String, value: String) {
        self.name = name
        self.value = value
    }
}
