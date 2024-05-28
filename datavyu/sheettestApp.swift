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
    
    @StateObject var appState = AppState()
    
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(fileController)
                .environmentObject(appState)
                .onAppear {
                ValueTransformer.setValueTransformer(TimestampTransformer(), forName: .classNameTransformerName)
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
            }

            CommandGroup(replacing: CommandGroupPlacement.saveItem) {
                Button("Save Sheet", action: { showingSaveDialog.toggle() })
                    .keyboardShortcut(KeyEquivalent("s"))
            }
            
            CommandGroup(after: CommandGroupPlacement.windowList) {
                Button("Open Controller Window") {
                    appState.controllerWindow?.makeKeyAndOrderFront(self)
                }
            }
            
            
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
