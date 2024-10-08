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

    @Published var showingOpenDialog = false
    @Published var showingAlert = false
    @Published var errorMsg = ""
    @Published var showingSaveDialog = false
    @Published var showingColumnNameDialog = false
    @Published var showingCodeEditor = false
    @Published var showingColHideShow = false
    @Published var showingUpdateView = false
    @Published var showingScriptSelector = false
    @Published var scriptEngine = RubyScriptEngine()

    @Published var showingSaveCloseDiaglog = false

    @Published var layoutLabel = "Ordinal Layout"
    @Published var temporalLayout = false
    @Published var hideLabel = "Hide Controller"
    @Published var hideController = false

    @Published var draggingColumn: ColumnModel?

    @Published var server: DatavyuAPIServer?
    @Published var jumpValue = "00:00:01:000"

    @Published var currentSelectedOnset: Int = 0
    @Published var currentSelectedOffset: Int = 0

    @AppStorage(Config.autosaveUserDefaultsKey) var autosaveURLs: [URL] = []
    @AppStorage(Config.lastOpenedFileUserDefaultsKey) var lastOpenedURL: URL?
    @AppStorage("recentlyOpenedFiles") var recentlyOpenedFiles: [URL] = []
    @AppStorage("recentlyOpenedScripts") var recentlyOpenedScripts: [URL] = []

    @objc dynamic var playbackTime = 0.0

    func configure(fileController: FileControllerModel, fileModelWrapper: ReferenceFileDocumentConfiguration<FileModel>) {
        self.fileController = fileController
        self.fileController?.fileModels.append(fileModelWrapper.document)
    }

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
            Logger.info("Save result: \(result)")
            if result == .alertFirstButtonReturn {
                displaySavePanel(fileModel: fileModel)
            } else if result == .alertSecondButtonReturn {
                Logger.info("Got cancel")
                return false
            } else if result == .alertThirdButtonReturn {
                Logger.info("Got dont save")
            }
        } else {
            displaySavePanel(fileModel: fileModel)
        }

        return true
    }

    func setControllerWindow(win: NSWindow, fileModel: FileModel) {
        controllerWindows[fileModel] = win
    }

    func addVideoWindow(win: NSWindow, fileModel: FileModel) {
        videoWindows[fileModel, default: []].append(win)
    }

    func addScriptWindow(win: NSWindow, fileModel: FileModel) {
        scriptWindows[fileModel, default: []].append(win)
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

    func changeActiveFileModel(fileModel: FileModel) {
        if fileController?.activeFileModel != nil, fileModel != fileController!.activeFileModel {
            hideWindows(fileModel: fileController!.activeFileModel)
            fileController?.activeFileModel = fileModel
            showWindows(fileModel: fileModel)
        }
    }
}
