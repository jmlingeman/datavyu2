//
//  DatavyuView.swift
//  datavyu
//
//  Created by Jesse Lingeman on 7/1/23.
//

import SwiftUI

struct DatavyuView: View {
    @ObservedObject var fileModel: FileModel
    @State private var showingCodeEditor = false
    @State private var showingOptions = false
    @State private var showingColumnList = false
    @State private var layoutLabel = "Ordinal Layout"
    @State private var temporalLayout = false
    @State private var hideLabel = "Hide Controller"
    @State private var hideController = false

    
    @EnvironmentObject var fileController: FileControllerModel
    @Environment(\.undoManager) var undoManager

    var body: some View {
        ZStack {
            GeometryReader { gr in
                ControllerView(fileModel: fileModel, temporalLayout: $temporalLayout, hideController: $hideController)
                    .onAppear(perform: {
                        fileModel.sheetModel.setUndoManager(undoManager: undoManager!)
                    })
                    .environmentObject(fileModel.sheetModel)
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
                            Button("Hide/Show Columns") {
                                showingColumnList.toggle()
                            }
                            .sheet(isPresented: $showingColumnList) {
                                ColumnListView(sheetModel: fileModel.sheetModel).frame(width: gr.size.width / 2, height: gr.size.height / 2)
                            }
                            Button("Open File")
                            {
                                let panel = NSOpenPanel()
                                panel.allowsMultipleSelection = false
                                panel.canChooseDirectories = false
                                if panel.runModal() == .OK {
                                    fileController.openFile(inputFilename: panel.url!)
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

