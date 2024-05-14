//
//  MarkerModel.swift
//  datavyu
//
//  Created by Jesse Lingeman on 6/20/23.
//

import Foundation

class Marker: ObservableObject, Identifiable, Equatable, Codable {
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
    
    enum CodingKeys: CodingKey {
        case time
        case selected
        case videoDuration
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        time = try container.decode(Double.self, forKey: .time)
        selected = try container.decode(Bool.self, forKey: .selected)
        videoDuration = try container.decode(Double.self, forKey: .videoDuration)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(time, forKey: .time)
        try container.encode(selected, forKey: .selected)
        try container.encode(videoDuration, forKey: .videoDuration)
    }
}
