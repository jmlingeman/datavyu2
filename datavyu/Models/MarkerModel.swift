//
//  MarkerModel.swift
//  datavyu
//
//  Created by Jesse Lingeman on 6/20/23.
//

import Foundation

class Marker: ObservableObject, Identifiable {
    @Published var time: Double
    
    init(value: Double) {
        self.time = value
    }
}
