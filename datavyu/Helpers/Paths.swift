//
//  Paths.swift
//  datavyu
//
//  Created by Jesse Lingeman on 5/27/24.
//

import AppKit
import Foundation

enum Paths {
    static let applicationSupportFolder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!.appending(path: "datavyu2")
    static let transcriptionFolder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!.appending(path: "datavyu2").appending(path: "transcription_models")

    static func createDirectory(directory: URL) {
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        } catch {
            Logger.info(error)
        }
    }

    static func showInFinder(url: URL?) {
        guard let url = url else { return }
        if url.isDirectory {
            NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: url.path)
        } else {
            NSWorkspace.shared.activateFileViewerSelecting([url])
        }
    }
}

extension URL {
    /// IMPORTANT: this code return false even if file or directory does not exist(!!!)
    var isDirectory: Bool {
        hasDirectoryPath
    }
}
