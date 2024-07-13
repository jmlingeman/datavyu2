//
//  AppState.swift
//  datavyu
//
//  Created by Jesse Lingeman on 5/27/24.
//

import AppKit
import AVFoundation
import SwiftUI

public class AppState: NSObject, ObservableObject {
    @Published var fileController: FileControllerModel?

    @Published var controllerWindows: [FileModel: NSWindow] = [:]
    @Published var videoWindows: [FileModel: [NSWindow]] = [:]
    @Published var scriptWindows: [FileModel: [NSWindow]] = [:]
    @Published var layout: LayoutChoice = .init()
    @Published var zoomFactor = 1.0
    @Published var highlightMode = false
    @Published var focusMode = false
    @Published var quickKeyMode = false

    @Published var draggingColumn: ColumnModel?

    @AppStorage(Config.autosaveUserDefaultsKey) var autosaveURLs: [URL] = []

    @objc dynamic var playbackTime = 0.0

    func closeFile(fileModel: FileModel) {
        fileController?.closeFile(fileModel: fileModel)
        controllerWindows.removeValue(forKey: fileModel)
        videoWindows.removeValue(forKey: fileModel)
        scriptWindows.removeValue(forKey: fileModel)
    }

    func displaySavePanel(fileModel: FileModel, quicksaveAllowed: Bool = true) {
        if quicksaveAllowed, fileModel.fileURL != nil {
            let _ = saveOpfFile(fileModel: fileModel, outputFilename: fileModel.fileURL!)
            return
        }

        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [UTType.opf]
        if fileModel.fileURL != nil {
            savePanel.directoryURL = fileModel.fileURL!.deletingLastPathComponent()
        } else {
            savePanel.directoryURL = Config.defaultSaveDirectory
        }
        savePanel.nameFieldStringValue = fileModel.sheetModel.sheetName
        if savePanel.runModal() == .OK {
            let _ = saveOpfFile(fileModel: fileModel, outputFilename: savePanel.url!)
        }
    }

    func savePanel(fileModel: FileModel, exiting: Bool = false) -> Bool {
        if exiting {
            let saveCloseAlert = NSAlert()
            saveCloseAlert.messageText = "Spreadsheet '\(fileModel.sheetModel.sheetName)' has unsaved changes."
            saveCloseAlert.informativeText = "Do you want to save before exiting?"
            saveCloseAlert.addButton(withTitle: "Save")
            saveCloseAlert.addButton(withTitle: "Cancel")
            saveCloseAlert.addButton(withTitle: "Don't Save").hasDestructiveAction = true

            let result = saveCloseAlert.runModal()
            print(result)
            if result == .alertFirstButtonReturn {
                displaySavePanel(fileModel: fileModel)
            } else if result == .alertSecondButtonReturn {
                print("Got cancel")
                return false
            } else if result == .alertThirdButtonReturn {
                print("Got dont save")
            }
        } else {
            displaySavePanel(fileModel: fileModel)
        }

        return true
    }

    func setControllerWindow(win: NSWindow) {
        controllerWindows[fileController!.activeFileModel] = win
    }

    func addVideoWindow(win: NSWindow) {
        videoWindows[fileController!.activeFileModel, default: []].append(win)
    }

    func addScriptWindow(win: NSWindow) {
        scriptWindows[fileController!.activeFileModel, default: []].append(win)
    }

    func removeVideo(fileModel: FileModel, videoTitle: String) {
        hideWindow(fileModel: fileModel, title: videoTitle)
        videoWindows[fileModel]?.removeAll { win in
            win.title == videoTitle
        }
    }

    func hideWindows(fileModel: FileModel) {
        controllerWindows[fileModel]?.orderOut(self)
        for vw in videoWindows[fileModel] ?? [] {
            vw.orderOut(self)
        }
        for sw in scriptWindows[fileModel] ?? [] {
            sw.orderOut(self)
        }
    }

    func hideWindow(fileModel: FileModel, title: String) {
        for vw in videoWindows[fileModel] ?? [] {
            if title == vw.title {
                vw.orderOut(self)
            }
        }
        for sw in scriptWindows[fileModel] ?? [] {
            if title == sw.title {
                sw.orderOut(self)
            }
        }
    }

    func showWindows(fileModel: FileModel) {
        controllerWindows[fileModel]?.orderFront(self)
        for vw in videoWindows[fileModel] ?? [] {
            vw.orderFront(self)
        }
        for sw in scriptWindows[fileModel] ?? [] {
            sw.orderFront(self)
        }
    }

    func showWindow(fileModel: FileModel, title: String) {
        for vw in videoWindows[fileModel] ?? [] {
            if title == vw.title {
                vw.orderFront(self)
            }
        }
        for sw in scriptWindows[fileModel] ?? [] {
            if title == sw.title {
                sw.orderFront(self)
            }
        }
    }

    func toggleHighlightMode() {
        highlightMode = !highlightMode
    }

    func toggleFocusMode() {
        focusMode = !focusMode
        if focusMode {
            highlightMode = true
        }
    }
}
