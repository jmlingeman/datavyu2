//
//  Config.swift
//  datavyu
//
//  Created by Jesse Lingeman on 6/6/23.
//

import Foundation
import SwiftUI

struct Config {
    let name = "Datavyu"
    let version = "0.0.1"
    
    let shuttleSpeeds: [Float] = [-32, -16, -8, -4, -2, -1, -1/2, -1/4, -1/8, -1/16, -1/32, 0, 1/32, 1/16, 1/8, 1/4, 1/2, 1, 2, 4, 8, 16, 32]
    
    let minCellHeight = 100
    let minCellWidth = 100
    let defaultCellWidth = 300.0
    let gapSize = 15.0
    let headerSize = 50.0
    
    /* Default Keybindings */
    let playKey = "w"
    let prevFrameKey = "q"
    let nextFrameKey = "e"
    let newCellBlankTimeKey = "a"
    let newCellAtTimeKey = "s"
    let pointCellKey = "d"
    
    /* Colorscheme */
    let cellBG = Color(red: 55 / 255, green: 74 / 255, blue: 115 / 255)
    let cellFG = Color.white
    let cellBorder = Color.black
    
    
}
