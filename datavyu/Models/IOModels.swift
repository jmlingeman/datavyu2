//
//  IOModels.swift
//  datavyu
//
//  Created by Jesse Lingeman on 7/8/23.
//

import Foundation
import Yams

struct ProjectFile: Codable {
    var dbFile: String
    var name: String
    var origpath: String
    var version: Int
    var viewerSettings: [ViewerSetting]
}

struct ViewerSetting: Codable {
    var classifier: String
    var feed: String
    var plugin: String
    var settingsId: String
    var trackSettings: TrackSetting
    var version: Int
}

struct TrackSetting: Codable {
    var bookmark: String = "-1"
    var bookmarks: [String] = []
    var locked: Bool = false
    var version: Int = 2
}

struct FileLoad {
    let file: FileModel
    var currentColumn: ColumnModel = .init(sheetModel: SheetModel(sheetName: "test"), columnName: "")
}
