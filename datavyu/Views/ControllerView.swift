//
//  ControllerView.swift
//  sheettest
//
//  Created by Jesse Lingeman on 6/3/23.
//

import AVKit
import CoreMedia
import SwiftUI

struct ControllerView: View {
    var fileModel: FileModel
    @Binding var temporalLayout: Bool
    @FocusState private var columnInFocus: ColumnModel?
    @FocusState private var cellInFocus: CellModel?
    @Binding var hideController: Bool
    @State private var showingColumnNameDialog = false

    func play() {
        for videoModel in fileModel.videoModels {
            videoModel.play()
        }
    }
    
    func shuttleStepUp() {
        fileModel.changeShuttleSpeed(step: 1)
    }
    
    func shuttleStepDown() {
        fileModel.changeShuttleSpeed(step: -1)
    }


    func stop() {
        for videoModel in fileModel.videoModels {
            videoModel.stop()
        }
        fileModel.syncVideos()
        fileModel.resetShuttleSpeed()
    }
    
    func pause() {
        for videoModel in fileModel.videoModels {
            videoModel.stop()
        }
        fileModel.syncVideos()
    }

    func nextFrame() {
        for videoModel in fileModel.videoModels {
            videoModel.nextFrame()
        }
    }

    func prevFrame() {
        for videoModel in fileModel.videoModels {
            videoModel.prevFrame()
        }
    }

    func addColumn() {
        let columnModel = ColumnModel(columnName: "")
        let _ = columnModel.addCell()
        let _ = columnModel.addCell()
        fileModel.sheetModel.addColumn(column: columnModel)
        columnInFocus = columnModel
        
        showingColumnNameDialog.toggle()
    }

    func addCell() {
        let cell = columnInFocus?.addCell()
        if cell != nil {
            cell?.setOnset(onset: fileModel.primaryVideo?.currentTime ?? 0)
        }
        fileModel.sheetModel.updates += 1 // Force sheetmodel updates of nested objects
    }
    
    func setOnset() {
        cellInFocus?.setOnset(onset: fileModel.currentTime())
    }
    
    func setOffset() {
        cellInFocus?.setOffset(offset: fileModel.currentTime())
    }
    
    func setOffsetAndAddNewCell() {
        cellInFocus?.setOffset(offset: fileModel.currentTime())
        let cell = columnInFocus?.addCell()
        cell?.setOnset(onset: fileModel.currentTime() + 1)
        cellInFocus = cell
    }
    
    func addVideo() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK {
            fileModel.addVideo(videoUrl: panel.url!)
        }
    }

    var body: some View {
            VStack {
                HSplitView {
                    if !hideController {
                        GeometryReader { gr in
                            Grid {
                                ForEach(fileModel.videoModels) { videoModel in
                                    GridRow {
                                        VideoView(videoModel: videoModel)
                                    }
                                }
                                GridRow {
                                    TracksStackView(fileModel: fileModel)
                                }
                                GridRow {
                                    HStack {
                                        ControllerButton(buttonName: "Set\nOnset", action: setOnset, gr: gr)
                                            .keyboardShortcut("7", modifiers: .numericPad)
                                            .keyboardShortcut("[")
                                        ControllerButton(buttonName: "Play", action: play, gr: gr)
                                            .keyboardShortcut("8", modifiers: .numericPad)
                                            .keyboardShortcut(",")
                                        ControllerButton(buttonName: "Set\nOffset", action: setOffset, gr: gr)
                                            .keyboardShortcut("9", modifiers: .numericPad)
                                            .keyboardShortcut("]")
                                    }
                                }
                                GridRow {
                                    HStack {
                                        ControllerButton(buttonName: "Shuttle <", action: shuttleStepDown, gr: gr)
                                            .keyboardShortcut("4", modifiers: .numericPad)
                                            .keyboardShortcut(";")
                                        ControllerButton(buttonName: "Stop", action: stop, gr: gr)
                                            .keyboardShortcut("5", modifiers: .numericPad)
                                            .keyboardShortcut(".")
                                        ControllerButton(buttonName: "Shuttle >", action: shuttleStepUp, gr: gr)
                                            .keyboardShortcut("6", modifiers: .numericPad)
                                            .keyboardShortcut("'")
                                        
                                    }
                                }
                                GridRow {
                                    HStack {
                                        ControllerButton(buttonName: "Prev", action: prevFrame, gr: gr)
                                            .keyboardShortcut("1", modifiers: .numericPad)
                                            .keyboardShortcut("-")
                                        ControllerButton(buttonName: "Pause", action: pause, gr: gr)
                                            .keyboardShortcut("2", modifiers: .numericPad)
                                            .keyboardShortcut("/")
                                        ControllerButton(buttonName: "Next", action: nextFrame, gr: gr)
                                            .keyboardShortcut("3", modifiers: .numericPad)
                                            .keyboardShortcut("=")
                                        
                                    }
                                }
                                GridRow {
                                    HStack {
                                        ControllerButton(buttonName: "Add Cell", action: addCell, gr: gr)
                                            .keyboardShortcut("9", modifiers: .numericPad)
                                            .keyboardShortcut("]")
                                        ControllerButton(buttonName: "Set Offset + Add", action: setOffsetAndAddNewCell, gr: gr)
                                            .keyboardShortcut("9", modifiers: .numericPad)
                                            .keyboardShortcut("]")
                                        ControllerButton(buttonName: "Add Col", action: addColumn, gr: gr)
                                            .keyboardShortcut("9", modifiers: .numericPad)
                                            .keyboardShortcut("]")
                                            .sheet(isPresented: $showingColumnNameDialog) {
                                                ColumnNameDialog(column: (columnInFocus ?? fileModel.sheetModel.columns.last)!)
                                        }
                                        ControllerButton(buttonName: "Add Video", action: addVideo, gr: gr)
                                            .keyboardShortcut("9", modifiers: .numericPad)
                                            .keyboardShortcut("]")
                                    }
                                }
                            }.padding().frame(minWidth: 300)
                        }.layoutPriority(2)
                    }
                    Sheet(sheetDataModel: fileModel.sheetModel, columnInFocus: _columnInFocus, cellInFocus: _cellInFocus, temporalLayout: $temporalLayout).frame(minWidth: 600).layoutPriority(1)
                }
            
            }
    }
}

struct ControllerView_Previews: PreviewProvider {
    static var previews: some View {
        let fileModel = FileModel(sheetModel: SheetModel(sheetName: "IMG_1234"), videoModels: [VideoModel(videoFilePath: URL(fileURLWithPath: "/Users/jesse/Downloads/IMG_0822.MOV"))])
        @State var temporalLayout = false
        @State var hideController = false

        ControllerView(fileModel: fileModel, temporalLayout: $temporalLayout, hideController: $hideController)
    }
}
