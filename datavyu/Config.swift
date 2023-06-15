//
//  Config.swift
//  datavyu
//
//  Created by Jesse Lingeman on 6/6/23.
//

import Foundation

struct Config {
    let name = "Datavyu"
    let version = "0.0.1"
    
    let minCellHeight = 100
    let minCellWidth = 100
    let defaultCellWidth = 300
    
    /* Default Keybindings */
    let playKey = "w"
    let prevFrameKey = "q"
    let nextFrameKey = "e"
    let newCellBlankTimeKey = "a"
    let newCellAtTimeKey = "s"
    let pointCellKey = "d"
}
