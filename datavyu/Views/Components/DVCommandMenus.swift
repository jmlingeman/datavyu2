//
//  DVCommandMenus.swift
//  Datavyu2
//
//  Created by Jesse Lingeman on 7/14/24.
//

import SwiftUI

struct DVCommandMenus: Commands {
    @ObservedObject var appState: AppState
    let keyInputSubject: KeyInputSubjectWrapper
    @FocusedObject private var fileModel: FileModel?

    func keyInput(_ key: KeyEquivalent, modifiers: EventModifiers = .none) -> some View {
        keyboardShortcut(key, sender: keyInputSubject, modifiers: modifiers)
    }

    var body: some Commands {
        CommandGroup(after: CommandGroupPlacement.appVisibility) {
            Button("Check for Updates") {
                appState.showingUpdateView.toggle()
            }
        }

        //            CommandGroup(replacing: CommandGroupPlacement.newItem) {
        //                Button("New Sheet", action: fileController.newFileDefault)
        //                    .keyboardShortcut(KeyEquivalent("n"))
        //                Button("Open Sheet") {
        //
        //                    NSOpenPanel()
        //                    Task {
        //                        do {
        //                            try await openDocument(at: appState.lastOpenedURL?)
        //                        }
        //                    }
        //                }
        ////                    .keyboardShortcut(KeyEquivalent("o"))
        //
        //                // TODO: Previously opened files
        //            }

        CommandGroup(after: CommandGroupPlacement.newItem) {
            Menu("Open Recent Files") {
                ForEach(appState.recentlyOpenedFiles, id: \.self) { fileUrl in
                    Button(fileUrl.path(percentEncoded: false)) {
                        let fileModel = loadOpfFile(inputFilename: fileUrl)
                        do {
                            try NSDocumentController.shared.makeDocument(withContentsOf: fileUrl, ofType: FileModel.type)
                        } catch {
                            print(error)
                        }
                    }
                }
            }
        }

//        CommandGroup(replacing: CommandGroupPlacement.saveItem) {
//            Button("Save Sheet", action: { appState.showingSaveDialog.toggle() })
//                .keyboardShortcut(KeyEquivalent("s"))
//        }

        CommandGroup(after: CommandGroupPlacement.windowList) {
            Divider()
            Button("Open Controller Window") {
                appState.controllerWindows[fileModel!]?.makeKeyAndOrderFront(self)
            }
            Divider()
        }

        CommandGroup(after: CommandGroupPlacement.textFormatting) {
            Divider()
            Button("Increase Font Size") {
                let zoomFactor = appState.zoomFactor + Config.textSizeIncrement
                appState.zoomFactor = min(zoomFactor, Config.maxTextSizeIncrement)
            }.keyboardShortcut(KeyEquivalent("="))
            Button("Decrease Font Size") {
                let zoomFactor = appState.zoomFactor - Config.textSizeIncrement
                appState.zoomFactor = max(zoomFactor, Config.minTextSizeIncrement)
            }.keyboardShortcut(KeyEquivalent("-"))
        }

        CommandMenu("Spreadsheet") {
            Button("Add Column") {
                let columnModel = appState.fileController?.activeFileModel.sheetModel.addColumn()
                if columnModel != nil {
                    appState.fileController?.activeFileModel.sheetModel.setSelectedColumn(model: columnModel!)
                    appState.showingColumnNameDialog.toggle()
                }
            }
            Button("Delete Column") {
                let selectedColumns = appState.fileController!.activeFileModel.sheetModel.getSelectedColumns()
                for column in selectedColumns {
                    appState.fileController!.activeFileModel.sheetModel.deleteColumn(column: column)
                }
            }
            Button("Show All Columns") {
                for column in appState.fileController!.activeFileModel.sheetModel.columns {
                    column.setHidden(val: false)
                }
            }
            Button("Hide Column") {
                appState.fileController!.activeFileModel.sheetModel.getSelectedColumns().first?.setHidden(val: true)
            }.keyboardShortcut(KeyEquivalent("h"), modifiers: .command)
            Button("Hide/Show Columns") {
                appState.showingColHideShow.toggle()
            }
            Divider()
            Button("Add Cell") {
                let col = appState.fileController!.activeFileModel.sheetModel.getSelectedColumns().first
                let _ = col?.addCell()
            }
            Button("Delete Cell") {
                appState.fileController!.activeFileModel.sheetModel.selectedCell?.deleteCell()
            }.keyboardShortcut(KeyEquivalent("\\"), modifiers: .command)
            Button("Add Cell in Column to the Left") {
                let selectedCell = appState.fileController!.activeFileModel.sheetModel.selectedCell
                if selectedCell != nil {
                    let colIdx = appState.fileController!.activeFileModel.sheetModel.visibleColumns.firstIndex(of: selectedCell!.column!)! - 1
                    if colIdx >= 0 {
                        let _ = appState.fileController!.activeFileModel.sheetModel.visibleColumns[colIdx].addCell(onset: selectedCell!.onset, offset: selectedCell!.offset)
                    }
                }
            }.keyboardShortcut(KeyEquivalent("l"), modifiers: .command)
            Button("Add Cell in Column to the Right") {
                let selectedCell = appState.fileController!.activeFileModel.sheetModel.selectedCell
                if selectedCell != nil {
                    let colIdx = appState.fileController!.activeFileModel.sheetModel.visibleColumns.firstIndex(of: selectedCell!.column!)! + 1
                    if colIdx < appState.fileController!.activeFileModel.sheetModel.visibleColumns.count {
                        let _ = appState.fileController!.activeFileModel.sheetModel.visibleColumns[colIdx].addCell(onset: selectedCell!.onset, offset: selectedCell!.offset)
                    }
                }
            }.keyboardShortcut(KeyEquivalent("r"), modifiers: .command)
            Divider()
            Button("Edit Columns/Arguments") {
                appState.showingCodeEditor.toggle()
            }
            Divider()
            Button {
                appState.layout.swapLayout()
            } label: {
                Text("Switch Spreadsheet Layout")
            }.keyboardShortcut(KeyEquivalent("t"), modifiers: .command)
            Divider()
            Button(appState.quickKeyMode ? "Enable Quick Key Mode" : "Disable Quick Key Mode") {
                appState.quickKeyMode.toggle()
            }.keyboardShortcut(KeyEquivalent("k"), modifiers: [.command, .shift])

            Divider()

            Button("Snap Region to Selected Cell") {
                appState.fileController?.activeFileModel.snapToRegion()
            }.keyboardShortcut(KeyEquivalent("+"), modifiers: .control)

            Button("Clear Selected Region") {
                appState.fileController?.activeFileModel.clearRegion()
            }.keyboardShortcut(KeyEquivalent("-"), modifiers: .control)
        }

        // A blank CommandMenu name hides the menu from the UI
        // So we can use this to manage our KB shortcuts w/o
        // showing this to the user.

        CommandMenu("") {
            ForEach(Config.quickKeyCharacters.split(separator: ""), id: \.self) { c in
                keyInput(KeyEquivalent(c.first!)).disabled(!appState.quickKeyMode)
            }

            Button("Next Cell in Column") {}.keyboardShortcut(KeyEquivalent.downArrow)

            // Numpad shortcut buttons
            Button("Set\nOnset") {
                appState.fileController!.activeFileModel.videoController!.setOnset()
            }.keyboardShortcut("7", modifiers: .numericPad)
            Button("Play") {
                appState.fileController!.activeFileModel.videoController!.play()
            }.keyboardShortcut("8", modifiers: .numericPad)
            Button("Set Offset") {
                appState.fileController!.activeFileModel.videoController!.setOffset()
            }.keyboardShortcut("9", modifiers: .numericPad)
            Button("Jump") {
                appState.fileController!.activeFileModel.videoController!.jump()
            }.keyboardShortcut("-", modifiers: .numericPad)
            Button("Shuttle <") {
                appState.fileController!.activeFileModel.videoController!.shuttleStepDown()
            }.keyboardShortcut("4", modifiers: .numericPad)
            Button("Stop") {
                appState.fileController!.activeFileModel.videoController!.stop()
            }.keyboardShortcut("5", modifiers: .numericPad)
            Button("Shuttle >") {
                appState.fileController!.activeFileModel.videoController!.shuttleStepUp()
            }.keyboardShortcut("6", modifiers: .numericPad)
            Button("Find Onset") {
                appState.fileController!.activeFileModel.videoController!.findOnset()
            }.keyboardShortcut("+", modifiers: .numericPad)
            Button("Find Offset") {
                appState.fileController!.activeFileModel.videoController!.findOffset()
            }.keyboardShortcut("+", modifiers: EventModifiers(rawValue: EventModifiers.shift.rawValue + EventModifiers.numericPad.rawValue))
            Button("Prev") {
                appState.fileController!.activeFileModel.videoController!.prevFrame()
            }.keyboardShortcut("1", modifiers: .numericPad)
            Button("Pause") {
                appState.fileController!.activeFileModel.videoController!.pause()
            }.keyboardShortcut("2", modifiers: .numericPad)
            Button("Next") {
                appState.fileController!.activeFileModel.videoController!.nextFrame()
            }.keyboardShortcut("3", modifiers: .numericPad)
            Button("Add Cell") {
                appState.fileController!.activeFileModel.videoController!.addCell()
            }.keyboardShortcut("0", modifiers: .numericPad)
            Button("Set Offset and Add Cell") {
                appState.fileController!.activeFileModel.videoController!.setOffsetAndAddNewCell()
            }.keyboardShortcut(".", modifiers: .numericPad)

            // Normal keyboard shortcut buttons
            Button("Set\nOnset") {
                appState.fileController!.activeFileModel.videoController!.setOnset()
            }.keyboardShortcut("i", modifiers: [.command, .shift])
            Button("Play") {
                appState.fileController!.activeFileModel.videoController!.play()
            }.keyboardShortcut("o", modifiers: [.command, .shift])
            Button("Set Offset") {
                appState.fileController!.activeFileModel.videoController!.setOffset()
            }.keyboardShortcut("p", modifiers: [.command, .shift])
            Button("Jump") {
                appState.fileController!.activeFileModel.videoController!.jump()
            }.keyboardShortcut("[", modifiers: [.command, .shift])
            Button("Shuttle <") {
                appState.fileController!.activeFileModel.videoController!.shuttleStepDown()
            }.keyboardShortcut("k", modifiers: [.command, .shift])
            Button("Stop") {
                appState.fileController!.activeFileModel.videoController!.stop()
            }.keyboardShortcut("l", modifiers: [.command, .shift])
            Button("Shuttle >") {
                appState.fileController!.activeFileModel.videoController!.shuttleStepUp()
            }.keyboardShortcut(";", modifiers: [.command, .shift])
            Button("Find Onset") {
                appState.fileController!.activeFileModel.videoController!.findOnset()
            }.keyboardShortcut("'", modifiers: [.command, .shift])
            Button("Find Offset") {
                appState.fileController!.activeFileModel.videoController!.findOffset()
            }.keyboardShortcut("'", modifiers: EventModifiers(rawValue: EventModifiers.shift.rawValue + EventModifiers.command.rawValue))
            Button("Prev") {
                appState.fileController!.activeFileModel.videoController!.prevFrame()
            }.keyboardShortcut(",", modifiers: [.command, .shift])
            Button("Pause") {
                appState.fileController!.activeFileModel.videoController!.pause()
            }.keyboardShortcut(".", modifiers: [.command, .shift])
            Button("Next") {
                appState.fileController!.activeFileModel.videoController!.nextFrame()
            }.keyboardShortcut("/", modifiers: [.command, .shift])
            Button("Add Cell") {
                appState.fileController!.activeFileModel.videoController!.addCell()
            }.keyboardShortcut("j", modifiers: [.command, .shift])
            Button("Set Offset and Add Cell") {
                appState.fileController!.activeFileModel.videoController!.setOffsetAndAddNewCell()
            }.keyboardShortcut("m", modifiers: [.command, .shift])
        }

        CommandMenu("Scripting") {
            Button("Run Script") {
                let panel = NSOpenPanel()
                panel.allowsMultipleSelection = false
                panel.canChooseDirectories = false
                panel.allowedContentTypes = [UTType.rubyScript, UTType.rscript]
                if panel.runModal() == .OK, fileModel != nil {
                    ScriptOutputWindow(url: panel.url!, fileModel: fileModel!, scriptEngine: appState.scriptEngine).openInWindow(title: "Script Output", appState: appState, fileModel: fileModel!, sender: self, frameName: nil)
                    appState.recentlyOpenedScripts.append(panel.url!)
                    appState.fileController!.activeFileModel.associatedScripts.append(panel.url!)
                }
            }
            Divider()
            Menu("Run Recent Script") {
                ForEach(appState.recentlyOpenedScripts, id: \.self) { script in
                    Button(script.path(percentEncoded: false)) {
                        if fileModel != nil {
                            ScriptOutputWindow(url: script, fileModel: fileModel!, scriptEngine: appState.scriptEngine).openInWindow(title: "Script Output", appState: appState, fileModel: fileModel!, sender: self, frameName: nil)
                        }
                    }
                }
            }
            Menu("Run Associated Script") {
                ForEach(appState.fileController?.activeFileModel.associatedScripts ?? [], id: \.self) { script in
                    Button(script.path(percentEncoded: false)) {
                        if fileModel != nil {
                            ScriptOutputWindow(url: script, fileModel: fileModel!, scriptEngine: appState.scriptEngine).openInWindow(title: "Script Output", appState: appState, fileModel: fileModel!, sender: self, frameName: nil)
                        }
                    }
                }
            }

            // TODO: Previously run files
        }

        //            CommandMenu("History") {
        //                Button("Show ") {
        //
        //                }
        //            }
    }
}
