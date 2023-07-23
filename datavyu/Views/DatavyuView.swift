//
//  DatavyuView.swift
//  datavyu
//
//  Created by Jesse Lingeman on 7/1/23.
//

import SwiftUI

struct DatavyuView: View {
    @State var fileModel: FileModel
    @State private var showingCodeEditor = false
    @State private var showingOptions = false
    @State private var layoutLabel = "Ordinal Layout"
    @State private var temporalLayout = false
    @State private var hideLabel = "Hide Controller"
    @State private var hideController = false

    var body: some View {
        ZStack {
            GeometryReader { gr in
                ControllerView(fileModel: fileModel, temporalLayout: $temporalLayout, hideController: $hideController)
                    .toolbar {
                        ToolbarItemGroup {
                            Button("Code Editor") {
                                showingCodeEditor.toggle()
                            }
                            .sheet(isPresented: $showingCodeEditor) {
                                CodeEditorView(fileModel: fileModel).frame(width: gr.size.width / 2, height: gr.size.height / 2)
                            }
                            Button("Options") {
                                showingOptions.toggle()
                            }
                            .sheet(isPresented: $showingOptions) {
                                OptionsView().frame(width: gr.size.width / 2, height: gr.size.height / 2)
                            }
                            Button("Open File")
                            {
                                let panel = NSOpenPanel()
                                panel.allowsMultipleSelection = false
                                panel.canChooseDirectories = false
                                if panel.runModal() == .OK {
                                    fileModel = loadOpfFile(inputFilename: panel.url!)
                                }
                            }
                            Button("Save File")
                            {
                                let panel = NSSavePanel()
                                if panel.runModal() == .OK {
                                    saveOpfFile(fileModel: fileModel, outputFilename: panel.url!)
                                }
                            }
                            Button(layoutLabel) {
                                if layoutLabel == "Ordinal Layout" {
                                    layoutLabel = "Temporal Layout"
                                    temporalLayout = true
                                } else {
                                    layoutLabel = "Ordinal Layout"
                                    temporalLayout = false
                                }
                            }.keyboardShortcut("t")
                            Button(hideLabel) {
                                withAnimation {
                                    if hideLabel == "Hide Controller" {
                                        hideLabel = "Show Controller"
                                        hideController = true
                                    } else {
                                        hideLabel = "Hide Controller"
                                        hideController = false
                                    }
                                }
                            }.keyboardShortcut("g")
                        }
                    }
            }
        }
        
    }
}

struct DatavyuView_Previews: PreviewProvider {
    static var previews: some View {
        let fileModel = FileModel(sheetModel: SheetModel(sheetName: "IMG_1234"), videoModels: [VideoModel(videoFilePath: URL(fileURLWithPath: "/Users/jesse/Downloads/IMG_0822.MOV"))])

        DatavyuView(fileModel: fileModel)
    }
}
