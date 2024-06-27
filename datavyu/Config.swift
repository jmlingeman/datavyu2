//
//  Config.swift
//  datavyu
//
//  Created by Jesse Lingeman on 6/6/23.
//

import Foundation
import SwiftUI

enum Config {
    static let name = "Datavyu"
    static let version = "0.0.1"

    static let updateUrl = "https://api.github.com/repos/jmlingeman/Datavyu2/releases/latest"

    static let shuttleSpeeds: [Float] = [-32, -16, -8, -4, -2, -1, -1 / 2, -1 / 4, -1 / 8, -1 / 16, -1 / 32, 0, 1 / 32, 1 / 16, 1 / 8, 1 / 4, 1 / 2, 1, 2, 4, 8, 16, 32]

    static let quickKeyCharacters: String = "abcdefghijklmnopqrstuvwxyz0123456789"

    static let minCellHeight = 150
    static let minCellWidth = 100
    static let defaultCellWidth = 300.0
    static let gapSize = 15.0
    static let headerSize = 50.0

    /* Default Keybindings */
    static let playKey = "w"
    static let prevFrameKey = "q"
    static let nextFrameKey = "e"
    static let newCellBlankTimeKey = "a"
    static let newCellAtTimeKey = "s"
    static let pointCellKey = "d"

    /* Colorscheme */
    static let cellBG = Color(red: 55 / 255, green: 74 / 255, blue: 115 / 255)
    static let cellFG = Color.white
    static let cellBorder = Color.black

    static let defaultCellTextSize = 13.0
    static let textSizeIncrement = 0.25
    static let minTextSizeIncrement = 0.5
    static let maxTextSizeIncrement = 2.0
}
