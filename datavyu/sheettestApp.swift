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
                  videoModels: [
                      VideoModel(
                          videoFilePath: URL(fileURLWithPath: "/Users/jesse/Downloads/IMG_0822.MOV")),
                      VideoModel(
                          videoFilePath: URL(fileURLWithPath: "/Users/jesse/Downloads/IMG_1234.MOV")),
                  ]),
    ])
    @State private var showingOpenDialog = false
    @State private var showingAlert = false
    @State private var errorMsg = ""
    @State private var showingSaveDialog = false
    @State private var showingColumnNameDialog = false
    @State private var showingCodeEditor = false
    @State private var showingColHideShow = false
    
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
        }.commands {
            CommandGroup(replacing: CommandGroupPlacement.newItem) {
                Button("New Sheet", action: fileController.newFileDefault)
                    .keyboardShortcut(KeyEquivalent("n"))
                Button("Open Sheet",
                       action: { showingOpenDialog.toggle() })
                    .keyboardShortcut(KeyEquivalent("o"))
                
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
                Button("Ordinal Layout") {
                    appState.layout.layout = Layouts.ordinal
                }
                Button("Temporal Layout") {
                    appState.layout.layout = Layouts.temporal
                }
                Divider()
                Button("Hide Column") {
                    fileController.activeFileModel.sheetModel.getSelectedColumns().first?.setHidden(val: true)
                }
                Button("Hide/Show Columns") {
                    showingColHideShow.toggle()
                }
            }
            
            CommandMenu("Scripting") {
                Button("Run Script") {
                    
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
