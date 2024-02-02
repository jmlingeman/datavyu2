//
//  ControllerPanelView.swift
//  datavyu
//
//  Created by Jesse Lingeman on 8/26/23.
//

import SwiftUI

struct ControllerPanelView: View {
    @ObservedObject var fileModel: FileModel
    var gr: GeometryProxy
    @FocusState var columnInFocus: ColumnModel?
    @FocusState var cellInFocus: CellModel?
    
    @State var showingColumnNameDialog = false
    
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
        let columnModel = ColumnModel(sheetModel: fileModel.sheetModel, columnName: "")
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
        
        fileModel.sheetModel.updates += 1
    }
    
    var body: some View {
        Grid {
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
                    ControllerButton(buttonName: "Add\nCell", action: addCell, gr: gr)
                        .keyboardShortcut("0", modifiers: .numericPad)
                        .keyboardShortcut("c")
                    ControllerButton(buttonName: "Set\nOffset\n+ Add", action: setOffsetAndAddNewCell, gr: gr)
                        .keyboardShortcut(".", modifiers: .numericPad)
                        .keyboardShortcut("v")
                    ControllerButton(buttonName: "Add\nCol", action: addColumn, gr: gr)
                        .keyboardShortcut(KeyEquivalent.return, modifiers: .numericPad)
                        .keyboardShortcut("g")
                        .sheet(isPresented: $showingColumnNameDialog) {
                            ColumnNameDialog(column: (columnInFocus ?? fileModel.sheetModel.columns.last)!)
                        }
                }
            }
        }
    }
}
