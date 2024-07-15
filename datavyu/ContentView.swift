//
//  ContentView.swift
//  sheettest
//
//  Created by Jesse Lingeman on 5/28/23.
//

import AppKit
import SwiftUI
import WrappingHStack

struct ContentView: View {
    @ObservedObject var fileModel: FileModel

    @EnvironmentObject var fileController: FileControllerModel
    @EnvironmentObject var appState: AppState

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
            DatavyuView(fileModel: fileModel, temporalLayout: $temporalLayout, hideController: $hideController)
                .environmentObject(fileModel.sheetModel)
                .environmentObject(fileModel)
                .focusedSceneObject(fileModel)
//            .onChange(of: fileController.activeFileModel) { oldValue, newValue in
//                let newTabIdx = fileController.fileModels.firstIndex(of: newValue)
//                selectedTab = newTabIdx ?? 0
//
//                // Hide all of the windows for this tab
//                appState.hideWindows(fileModel: oldValue)
//                appState.showWindows(fileModel: newValue)
//            }
//            .onChange(of: selectedTab) { _, _ in
//                fileController.activeFileModel = fileController.fileModels[selectedTab]
//            }
                .toolbar {
                    ToolbarItemGroup {
                        Button("Code Editor") {
                            showingCodeEditor.toggle()
                        }
                        .sheet(isPresented: $showingCodeEditor) {
                            CodeEditorView(sheetModel: fileModel.sheetModel).frame(width: gr.size.width / 2, height: gr.size.height / 2)
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
//                    Button(layoutLabel) {
//                        if layoutLabel == "Ordinal Layout" {
//                            layoutLabel = "Temporal Layout"
//                            temporalLayout = true
//                        } else {
//                            layoutLabel = "Ordinal Layout"
//                            temporalLayout = false
//                        }
//                    }.keyboardShortcut("t")
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
