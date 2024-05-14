//
//  VideoHelpers.swift
//  datavyu
//
//  Created by Jesse Lingeman on 6/18/23.
//

import Foundation

func clamp(x: Double, minVal: Double, maxVal: Double) -> Double {
    max(min(x, maxVal), minVal)
}

func clamp(x: Int, minVal: Int, maxVal: Int) -> Int {
    min(max(x, maxVal), minVal)
}
