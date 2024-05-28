//
//  ContentView.swift
//  sheettest
//
//  Created by Jesse Lingeman on 5/28/23.
//

import SwiftUI
import WrappingHStack

struct ContentView: View {
    @EnvironmentObject var fileController: FileControllerModel
    @State var selectedTab = 0

    @State private var showingCodeEditor = false
    @State private var showingOptions = false
    @State private var showingColumnList = false
    @State private var layoutLabel = "Ordinal Layout"
    @State private var temporalLayout = false
    @State private var hideLabel = "Hide Controller"
    @State private var hideController = false

    var body: some View {
        GeometryReader { gr in
            TabView(selection: $selectedTab) {
                ForEach(Array(zip(fileController.fileModels.indices, $fileController.fileModels)), id: \.0) { idx, $fileModel in
                    DatavyuView(fileModel: fileModel, temporalLayout: $temporalLayout, hideController: $hideController).tabItem { Text(fileModel.sheetModel.sheetName) }
                        .environmentObject(fileModel.sheetModel)
                        .environmentObject(fileModel).tag(idx)
                }
            }
            .onAppear {
                let server = DatavyuAPIServer(fileController: fileController, port: 1312)
                server.start()
            }
            .onChange(of: fileController.activeFileModel) { _, newValue in
                let newTabIdx = fileController.fileModels.firstIndex(of: newValue)
                selectedTab = newTabIdx ?? 0
            }
            .toolbar {
                ToolbarItemGroup {
                    Button("Code Editor") {
                        showingCodeEditor.toggle()
                    }
                    .sheet(isPresented: $showingCodeEditor) {
                        CodeEditorView(sheetModel: fileController.activeFileModel.sheetModel).frame(width: gr.size.width / 2, height: gr.size.height / 2)
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
                        ColumnListView(sheetModel: fileController.activeFileModel.sheetModel).frame(width: gr.size.width / 2, height: gr.size.height / 2)
                    }
                    Button("Open File") {
                        let panel = NSOpenPanel()
                        panel.allowsMultipleSelection = false
                        panel.canChooseDirectories = false
                        if panel.runModal() == .OK {
                            fileController.openFile(inputFilename: panel.url!)
                        }
                    }
                    Button("Save File") {
                        let panel = NSSavePanel()
                        if panel.runModal() == .OK {
                            let _ = saveOpfFile(fileModel: fileController.activeFileModel, outputFilename: panel.url!)
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
