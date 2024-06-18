//
//  sheettestApp.swift
//  sheettest
//
//  Created by Jesse Lingeman on 5/28/23.
//

import SwiftUI
import UniformTypeIdentifiers

@main
struct sheettestApp: App {
//    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject var fileController: FileControllerModel = .init(fileModels: [
        FileModel(sheetModel: SheetModel(sheetName: "Test Sheet", run_setup: false),
                  videoModels: []),
    ])
    @State private var showingOpenDialog = false
    @State private var showingAlert = false
    @State private var errorMsg = ""
    @State private var showingSaveDialog = false
    @State private var showingColumnNameDialog = false
    @State private var showingCodeEditor = false
    @State private var showingColHideShow = false
    @State private var showingUpdateView = false
    @State private var showingScriptSelector = false
    @State private var scriptEngine = RubyScriptEngine()

    @StateObject var appState: AppState = .init()

    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    appState.fileController = fileController
                    ValueTransformer.setValueTransformer(TimestampTransformer(), forName: .classNameTransformerName)
                }
                .environmentObject(fileController)
                .environmentObject(appState)
                .sheet(isPresented: $showingColumnNameDialog) {
                    ColumnNameDialog(column: (fileController.activeFileModel.sheetModel.columns.last)!)
                }
                .sheet(isPresented: $showingCodeEditor) {
                    CodeEditorView(sheetModel: fileController.activeFileModel.sheetModel)
                }
                .sheet(isPresented: $showingColHideShow) {
                    ColumnListView(sheetModel: fileController.activeFileModel.sheetModel)
                }
                .sheet(isPresented: $showingUpdateView) {
                    UpdateView(appState: appState)
                }
                .alert(isPresented: $showingAlert) {
                    Alert(title: Text("Error: File error"), message: Text(errorMsg))
                }
                .fileExporter(isPresented: $showingSaveDialog,
                              document: fileController.activeFileModel,
                              contentType: UTType.opf,
                              defaultFilename: "\(fileController.activeFileModel.sheetModel.sheetName).opf",
                              onCompletion: { result in
                                  switch result {
                                  case let .success(url):
                                      fileController.saveFile(outputFilename: url)
                                  case let .failure(error):
                                      errorMsg = "\(error)"
                                      showingAlert.toggle()
                                  }
                              })
                .fileImporter(isPresented: $showingOpenDialog,
                              allowedContentTypes: [UTType.opf],
                              allowsMultipleSelection: true,
                              onCompletion: { result in

                                  switch result {
                                  case let .success(urls):
                                      for url in urls {
                                          fileController.openFile(inputFilename: url)
                                      }
                                  case let .failure(error):
                                      errorMsg = "\(error)"
                                      showingAlert.toggle()
                                  }
                              })
        }.commands {
            CommandGroup(after: CommandGroupPlacement.appVisibility) {
                Button("Check for Updates") {
                    showingUpdateView.toggle()
                }
            }
            CommandGroup(replacing: CommandGroupPlacement.newItem) {
                Button("New Sheet", action: fileController.newFileDefault)
                    .keyboardShortcut(KeyEquivalent("n"))
                Button("Open Sheet",
                       action: { showingOpenDialog.toggle() })
//                    .keyboardShortcut(KeyEquivalent("o"))

                // TODO: Previously opened files
            }

            CommandGroup(replacing: CommandGroupPlacement.saveItem) {
                Button("Save Sheet", action: { showingSaveDialog.toggle() })
                    .keyboardShortcut(KeyEquivalent("s"))
            }

            CommandGroup(after: CommandGroupPlacement.windowList) {
                Divider()
                Button("Open Controller Window") {
                    appState.controllerWindows[fileController.activeFileModel]?.makeKeyAndOrderFront(self)
                }
                Divider()
            }

            CommandMenu("Spreadsheet") {
                Button("Add Column") {
                    let columnModel = fileController.activeFileModel.sheetModel.addColumn()
                    fileController.activeFileModel.sheetModel.setSelectedColumn(model: columnModel)
                    showingColumnNameDialog.toggle()
                }
                Button("Delete Column") {
                    let selectedColumns = fileController.activeFileModel.sheetModel.getSelectedColumns()
                    for column in selectedColumns {
                        fileController.activeFileModel.sheetModel.deleteColumn(column: column)
                    }
                }
                Divider()
                Button("Add Cell") {
                    let col = fileController.activeFileModel.sheetModel.getSelectedColumns().first
                    col?.addCell()
                }
                Button("Delete Cell") {
                    fileController.activeFileModel.sheetModel.selectedCell?.deleteCell()
                }
                Divider()
                Button("Edit Columns/Arguments") {
                    showingCodeEditor.toggle()
                }
                Divider()
                Button {
                    appState.layout.swapLayout()
                } label: {
                    Text("Switch Spreadsheet Layout")
                }.keyboardShortcut(KeyEquivalent("t"), modifiers: .command)
                Divider()
                Button("Hide Column") {
                    fileController.activeFileModel.sheetModel.getSelectedColumns().first?.setHidden(val: true)
                }
                Button("Hide/Show Columns") {
                    showingColHideShow.toggle()
                }
            }

            // A blank CommandMenu name hides the menu from the UI
            // So we can use this to manage our KB shortcuts w/o
            // showing this to the user.

            CommandMenu("") {
                // Numpad shortcut buttons
                Button("Set\nOnset") {
                    fileController.activeFileModel.videoController!.setOnset()
                }.keyboardShortcut("7", modifiers: .numericPad)
                Button("Play") {
                    fileController.activeFileModel.videoController!.play()
                }.keyboardShortcut("8", modifiers: .numericPad)
                Button("Set Offset") {
                    fileController.activeFileModel.videoController!.setOffset()
                }.keyboardShortcut("9", modifiers: .numericPad)
                Button("Jump") {
                    fileController.activeFileModel.videoController!.jump()
                }.keyboardShortcut("-", modifiers: .numericPad)
                Button("Shuttle <") {
                    fileController.activeFileModel.videoController!.shuttleStepDown()
                }.keyboardShortcut("4", modifiers: .numericPad)
                Button("Stop") {
                    fileController.activeFileModel.videoController!.stop()
                }.keyboardShortcut("5", modifiers: .numericPad)
                Button("Shuttle >") {
                    fileController.activeFileModel.videoController!.shuttleStepUp()
                }.keyboardShortcut("6", modifiers: .numericPad)
                Button("Find Onset") {
                    fileController.activeFileModel.videoController!.findOnset()
                }.keyboardShortcut("+", modifiers: .numericPad)
                Button("Find Offset") {
                    fileController.activeFileModel.videoController!.findOffset()
                }.keyboardShortcut("+", modifiers: EventModifiers(rawValue: EventModifiers.shift.rawValue + EventModifiers.numericPad.rawValue))
                Button("Prev") {
                    fileController.activeFileModel.videoController!.prevFrame()
                }.keyboardShortcut("1", modifiers: .numericPad)
                Button("Pause") {
                    fileController.activeFileModel.videoController!.pause()
                }.keyboardShortcut("2", modifiers: .numericPad)
                Button("Next") {
                    fileController.activeFileModel.videoController!.nextFrame()
                }.keyboardShortcut("3", modifiers: .numericPad)
                Button("Add Cell") {
                    fileController.activeFileModel.videoController!.addCell()
                }.keyboardShortcut("0", modifiers: .numericPad)
                Button("Set Offset and Add Cell") {
                    fileController.activeFileModel.videoController!.setOffsetAndAddNewCell()
                }.keyboardShortcut(".", modifiers: .numericPad)

                // Normal keyboard shortcut buttons
                Button("Set\nOnset") {
                    fileController.activeFileModel.videoController!.setOnset()
                }.keyboardShortcut("i", modifiers: .command)
                Button("Play") {
                    fileController.activeFileModel.videoController!.play()
                }.keyboardShortcut("o", modifiers: .command)
                Button("Set Offset") {
                    fileController.activeFileModel.videoController!.setOffset()
                }.keyboardShortcut("p", modifiers: .command)
                Button("Jump") {
                    fileController.activeFileModel.videoController!.jump()
                }.keyboardShortcut("[", modifiers: .command)
                Button("Shuttle <") {
                    fileController.activeFileModel.videoController!.shuttleStepDown()
                }.keyboardShortcut("k", modifiers: .command)
                Button("Stop") {
                    fileController.activeFileModel.videoController!.stop()
                }.keyboardShortcut("l", modifiers: .command)
                Button("Shuttle >") {
                    fileController.activeFileModel.videoController!.shuttleStepUp()
                }.keyboardShortcut(";", modifiers: .command)
                Button("Find Onset") {
                    fileController.activeFileModel.videoController!.findOnset()
                }.keyboardShortcut("'", modifiers: .command)
                Button("Find Offset") {
                    fileController.activeFileModel.videoController!.findOffset()
                }.keyboardShortcut("'", modifiers: EventModifiers(rawValue: EventModifiers.shift.rawValue + EventModifiers.command.rawValue))
                Button("Prev") {
                    fileController.activeFileModel.videoController!.prevFrame()
                }.keyboardShortcut(",", modifiers: .command)
                Button("Pause") {
                    fileController.activeFileModel.videoController!.pause()
                }.keyboardShortcut(".", modifiers: .command)
                Button("Next") {
                    fileController.activeFileModel.videoController!.nextFrame()
                }.keyboardShortcut("/", modifiers: .command)
                Button("Add Cell") {
                    fileController.activeFileModel.videoController!.addCell()
                }.keyboardShortcut("j", modifiers: .command)
                Button("Set Offset and Add Cell") {
                    fileController.activeFileModel.videoController!.setOffsetAndAddNewCell()
                }.keyboardShortcut("m", modifiers: .command)
            }

            CommandMenu("Scripting") {
                Button("Run Script") {
                    let panel = NSOpenPanel()
                    panel.allowsMultipleSelection = false
                    panel.canChooseDirectories = false
                    panel.allowedContentTypes = [UTType.rubyScript, UTType.rscript]
                    if panel.runModal() == .OK {
                        ScriptOutputWindow(url: panel.url!, fileModel: fileController.activeFileModel, scriptEngine: scriptEngine).openInWindow(title: "Script Output", appState: appState, sender: self, frameName: nil)
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
}

// class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
//
//    func applicationDidFinishLaunching(_ notification: Notification) {
//        // Set window delegate so we get close notifications
//        NSApp.windows.first?.delegate = self
//        // Restore last window frame
//        if let frameDescription = UserDefaults.standard.string(forKey: "MainWindowFrame") {
//            // To prevent the window from jumping we hide it
//            mainWindow.orderOut(self)
//            Task { @MainActor in
//                // Setting the frame only works after a short delay
//                try? await Task.sleep(for: .seconds(0.5))
//                mainWindow.setFrame(from: frameDescription)
//                // Show the window
//                mainWindow.makeKeyAndOrderFront(nil)
//            }
//        }
//    }
//
//    func windowShouldClose(_ sender: NSWindow) -> Bool {
//        if let mainWindow = NSApp.windows.first {
//            UserDefaults.standard.set(mainWindow.frameDescriptor, forKey: "MainWindowFrame")
//        }
//        return true
//    }
//
//    func applicationWillTerminate(_ notification: Notification) {
//        if let mainWindow = NSApp.windows.first {
//            UserDefaults.standard.set(mainWindow.frameDescriptor, forKey: "MainWindowFrame")
//        }
//    }
//
//    func applicationDidFinishLaunching(_ notification: Notification) {
//        let mainWindow = NSApp.windows.first
//        mainWindow?.delegate = self
//    }
//
//    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
//        let mainWindow = NSApp.windows.first
//        if flag {
//            mainWindow?.orderFront(nil)
//        } else {
//            mainWindow?.makeKeyAndOrderFront(nil)
//        }
//        return true
//    }
// }
