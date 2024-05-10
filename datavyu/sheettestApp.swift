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
    @StateObject var fileController: FileControllerModel = FileControllerModel(fileModels: [
        FileModel(sheetModel: SheetModel(sheetName: "Test Sheet", run_setup: false),
                  videoModels: [
                    VideoModel(
                        videoFilePath: URL(fileURLWithPath: "/Users/jesse/Downloads/IMG_0822.MOV")),
                    VideoModel(
                        videoFilePath: URL(fileURLWithPath: "/Users/jesse/Downloads/IMG_0822.MOV")),
                    VideoModel(
                        videoFilePath: URL(fileURLWithPath: "/Users/jesse/Downloads/IMG_1234.MOV")),
                  ])
    ])
    @State private var showingOpenDialog = false
    @State private var showingAlert = false
    @State private var errorMsg = ""
    @State private var showingSaveDialog = false
    
    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(fileController).onAppear {
                ValueTransformer.setValueTransformer(TimestampTransformer(), forName: .classNameTransformerName)
            }
            .fileImporter(isPresented: $showingOpenDialog,
                          allowedContentTypes: [UTType.opf],
                          allowsMultipleSelection: true,
                          onCompletion: { result in
                
                switch result {
                case .success(let urls):
                    for url in urls {
                        fileController.openFile(inputFilename: url)
                    }
                case .failure(let error):
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
                case .success(let url):
                    fileController.saveFile(outputFilename: url)
                case .failure(let error):
                    errorMsg = "\(error)"
                    showingAlert.toggle()
                }
            })
        }.commands {
            CommandGroup(replacing: CommandGroupPlacement.newItem) {
                Button("New Sheet", action: fileController.newFileDefault)
                    .keyboardShortcut(KeyEquivalent("n"))
                Button("Open Sheet",
                       action: {showingOpenDialog.toggle()})
                .keyboardShortcut(KeyEquivalent("o"))
            }
            
            CommandGroup(replacing: CommandGroupPlacement.saveItem) {
                Button("Save Sheet", action: {showingSaveDialog.toggle()})
                    .keyboardShortcut(KeyEquivalent("s"))
            }
        }
    }
}
