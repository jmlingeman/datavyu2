//
//  DatavyuApp.swift
//  sheettest
//
//  Created by Jesse Lingeman on 5/28/23.
//

import SwiftUI
import UniformTypeIdentifiers

final class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    var appState: AppState?

    func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
        true
    }

    func applicationDidFinishLaunching(_: Notification) {
//        flushSavedWindowState()

//        let autosaveURLs = appState?.autosaveURLs
//        if autosaveURLs != nil, autosaveURLs?.count ?? 0 > 0 {
//            // Prompt user to re-open file
//            let autosaveAlert = NSAlert()
//            let urlStrings = autosaveURLs!.map { url in
//                url.lastPathComponent
//            }
//            autosaveAlert.messageText = "Datavyu crashed and the following files were autosaved: \(urlStrings.joined(separator: ", "))"
//            autosaveAlert.informativeText = "Do you want to reopen these files?"
//            autosaveAlert.addButton(withTitle: "Open All")
//            autosaveAlert.addButton(withTitle: "Don't Open").hasDestructiveAction = true
//
//            let result = autosaveAlert.runModal()
//            if result == .alertFirstButtonReturn {
//                for url in autosaveURLs! {
//                    let fileModel = appState?.fileController?.openFile(inputFilename: url)
//                    fileModel?.unsavedChanges = true
//                }
//                appState?.autosaveURLs = []
//            } else if result == .alertSecondButtonReturn {
//                appState?.autosaveURLs = []
//            }
//
//
//        }
    }

    func startScriptServer() {
        appState!.server = DatavyuAPIServer(fileController: appState!.fileController!, port: 1312)
        appState!.server!.start()
    }

    func applicationShouldTerminate(_: NSApplication) -> NSApplication.TerminateReply {
        // some code
        if appState?.fileController != nil {
            for fileModel in appState!.fileController!.fileModels {
//                if fileModel.unsavedChanges {
//                    appState!.fileController!.activeFileModel = fileModel
//
//                    let res = appState!.savePanel(fileModel: fileModel, exiting: true)
//                    if !res {
//                        return .terminateCancel
//                    }
//                }
            }
        }

        // Since we're exiting normally, clear the autosaved files so we don't
        // try to reopen them.
        UserDefaults.standard.set([], forKey: Config.autosaveUserDefaultsKey)

        flushSavedWindowState()
        return .terminateNow
    }

    func flushSavedWindowState() {
        do {
            let libURL = try FileManager.default.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            guard let appPersistentStateDirName = Bundle.main.bundleIdentifier?.appending(".savedState") else { Logger.info("get bundleID failed"); return }
            let savedDataURL = libURL.appendingPathComponent("Saved Application State", isDirectory: true)
                .appendingPathComponent(appPersistentStateDirName, isDirectory: true)
            var files = [URL]()
            if let enumerator = FileManager.default.enumerator(at: savedDataURL, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) {
                for case let fileURL as URL in enumerator {
                    do {
                        let fileAttributes = try fileURL.resourceValues(forKeys: [.isRegularFileKey])
                        if fileAttributes.isRegularFile! {
                            files.append(fileURL)
                        }
                    } catch { Logger.info(error, fileURL) }
                }
                Logger.info(files)
            }
            for fileURL in files {
                Logger.info("path to remove: ", fileURL)
                try FileManager.default.removeItem(at: fileURL)
            }
//            let windowsPlistFilePath = libURL.appendingPathComponent("Saved Application State", isDirectory: true)
//                .appendingPathComponent(appPersistentStateDirName, isDirectory: true)
//                .appendingPathComponent("data.data", isDirectory: false)
//                .path
//
//            Logger.info("path to remove: ", windowsPlistFilePath)
//            try FileManager.default.removeItem(atPath: windowsPlistFilePath)
        } catch {
            Logger.info("exception: \(error)")
        }
    }
}

@main
struct DatavyuApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject var fileController: FileControllerModel = .init(fileModels: [
        FileModel(sheetModel: SheetModel(sheetName: "New Sheet", run_setup: false),
                  videoModels: []),
    ])

    @StateObject var appState: AppState = .init()

    @Environment(\.openWindow) private var openWindow
    @Environment(\.openDocument) private var openDocument
    @FocusedObject var fileModel: FileModel?
    private let keyInputSubject = KeyInputSubjectWrapper()

    var body: some Scene {
        DocumentGroup {
            FileModel()
        } editor: { fileModelWrapper in
            ContentView(fileModel: fileModelWrapper.document)
                .onAppear {
                    appDelegate.appState = appState
                    appDelegate.startScriptServer()
                    appState.fileController = fileController
                    appState.fileController?.fileModels.append(fileModelWrapper.document)
                    ValueTransformer.setValueTransformer(TimestampTransformer(), forName: .classNameTransformerName)
                }
                .environmentObject(fileController)
                .environmentObject(appState)
                .sheet(isPresented: $appState.showingColumnNameDialog) {
                    ColumnNameDialog(column: (fileModelWrapper.document.sheetModel.columns.last)!)
                }
                .sheet(isPresented: $appState.showingCodeEditor) {
                    CodeEditorView(sheetModel: fileModelWrapper.document.sheetModel)
                }
                .sheet(isPresented: $appState.showingColHideShow) {
                    ColumnListView(sheetModel: fileModelWrapper.document.sheetModel)
                }
                .sheet(isPresented: $appState.showingUpdateView) {
                    UpdateView(appState: appState)
                }
                .alert(isPresented: $appState.showingAlert) {
                    Alert(title: Text("Error: File error"), message: Text(appState.errorMsg))
                }
                .onChange(of: appState.showingSaveDialog, perform: { _ in
                    if appState.showingSaveDialog {
                        _ = appState.savePanel(fileModel: fileModelWrapper.document)
                    }
                    appState.showingSaveDialog = false
                })

//                .fileExporter(isPresented: $showingSaveDialog,
//                              document: fileController.activeFileModel,
//                              contentType: UTType.opf,
//                              defaultFilename: "\(fileController.activeFileModel.sheetModel.sheetName).opf",
//                              onCompletion: { result in
//                                  switch result {
//                                  case let .success(url):
//                                      fileController.saveFile(outputFilename: url)
//                                  case let .failure(error):
//                                      errorMsg = "\(error)"
//                                      showingAlert.toggle()
//                                  }
//                              })
//                .fileImporter(isPresented: $appState.showingOpenDialog,
//                              allowedContentTypes: [UTType.opf],
//                              allowsMultipleSelection: true,
//                              onCompletion: { result in
//
//                                  switch result {
//                                  case let .success(urls):
//                                      for url in urls {
//                                          Task {
//                                              do {
//                                                  try await openDocument(at: url)
//                                              } catch {
//                                                  Logger.info(error)
//                                              }
//                                          }
                ////                                          fileController.openFile(inputFilename: url)
//                                          appState.recentlyOpenedFiles.append(url)
//                                          if appState.recentlyOpenedFiles.count > Config.maxRecentFiles {
//                                              appState.recentlyOpenedFiles = Array(appState.recentlyOpenedFiles[max(0, appState.recentlyOpenedFiles.count - Config.maxRecentFiles) ..< appState.recentlyOpenedFiles.count])
//                                          }
//                                      }
//                                  case let .failure(error):
//                                      appState.errorMsg = "\(error)"
//                                      appState.showingAlert.toggle()
//                                  }
//                              })
                .onReceive(keyInputSubject) { c in
                    let cell = fileModelWrapper.document.sheetModel.getSelectedColumns().first?.addCell()
                    cell?.setArgumentValue(index: 0, value: String(c.character))
                    let time = secondsToMillis(secs: fileModelWrapper.document.currentTime())
                    cell?.onset = time
                    cell?.offset = time
                    fileModelWrapper.document.sheetModel.selectedCell = cell
                    fileModelWrapper.document.sheetModel.updateSheet()
                }
                .environmentObject(keyInputSubject)
                .contextMenu {
                    RenameButton()
                }
        }
        .commands {
            DVCommandMenus(appState: appState, keyInputSubject: keyInputSubject)
        }
//        .onChange(of: fileModel, perform: { _ in
//            if fileModel != nil {
//                appState.changeActiveFileModel(fileModel: fileModel!)
//            }
//        })
//        .onChange(of: fileModel, perform: { _ in            NSDocumentController.shared.closeAllDocuments(withDelegate: nil, didCloseAllSelector: nil, contextInfo: nil)
//            NSDocumentController.shared.newDocument(nil)
//        })
    }
}
