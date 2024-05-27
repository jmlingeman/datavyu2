//
//  Paths.swift
//  datavyu
//
//  Created by Jesse Lingeman on 5/27/24.
//

import Foundation

struct Paths {
    static let applicationSupportFolder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!.appending(path: "datavyu2")
    static let transcriptionFolder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!.appending(path: "datavyu2").appending(path: "transcription_models")
    
    static func createDirectory(directory: URL) {
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        } catch  {
            print(error)
        }
    }
}
