//
//  MarkerModel.swift
//  datavyu
//
//  Created by Jesse Lingeman on 6/20/23.
//

import Foundation

class Marker: ObservableObject, Identifiable, Equatable {
    static func == (lhs: Marker, rhs: Marker) -> Bool {
        lhs.time == rhs.time
    }
    
    @Published var time: Double
    @Published var selected: Bool
    @Published var videoDuration: Double
    
    init(value: Double, videoDuration: Double) {
        self.time = value
        self.selected = false
        self.videoDuration = videoDuration
    }
}
