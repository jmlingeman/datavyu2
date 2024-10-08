//
//  ControllerPanelView.swift
//  datavyu
//
//  Created by Jesse Lingeman on 8/26/23.
//

import SwiftUI

struct ControllerPanelView: View {
    @ObservedObject var fileModel: FileModel
    @ObservedObject var appState: AppState

    @State var showingColumnNameDialog = false
    @State var jumpValue: String = "00:00:05:000"

    @State var currentOnset: Int = 0
    @State var currentOffset: Int = 0

    @State var fps: String = ""

    func addColumn() {
        let columnModel = ColumnModel(sheetModel: fileModel.sheetModel, columnName: "Column\(fileModel.sheetModel.columns.count + 1)")
        fileModel.sheetModel.addColumn(column: columnModel)

        fileModel.sheetModel.focusController.setFocusedColumn(columnModel: columnModel)

        showingColumnNameDialog.toggle()
    }

    var body: some View {
        VStack {
            HStack(alignment: .center) {
                if fileModel.primaryVideo != nil {
                    VStack(alignment: .center) {
                        ClockView(videoModel: fileModel.primaryVideo!)
                    }
                }
            }
            Grid(alignment: .topLeading, horizontalSpacing: 2, verticalSpacing: 2) {
                GridRow {
                    ControllerButton(buttonName: "") {}.disabled(true)
                    ControllerButton(buttonName: "Point Cell") {
                        let currentTime = secondsToMillis(secs: fileModel.currentTime())
                        let _ = fileModel.sheetModel.getSelectedColumns().first?.addCell(onset: currentTime, offset: currentTime)
                    }
                    ControllerButton(buttonName: "") {}.disabled(true)
                    ControllerButton(buttonName: "") {}.disabled(true)
                }
                GridRow {
                    ControllerButton(buttonName: "Set\nOnset", action: fileModel.videoController!.setOnset)
//                        .keyboardShortcut("7", modifiers: .numericPad)
                        .keyboardShortcut("[", modifiers: .command)
                    ControllerButton(buttonName: "Play", action: fileModel.videoController!.play)
                        .keyboardShortcut("8", modifiers: .numericPad)
                        .keyboardShortcut(",")
                    ControllerButton(buttonName: "Set\nOffset", action: fileModel.videoController!.setOffset)
                        .keyboardShortcut("9", modifiers: .numericPad)
                        .keyboardShortcut("]")
                    ControllerButton(buttonName: "Jump", action: { fileModel.videoController!.jump(jumpValue: appState.jumpValue) })
                        .keyboardShortcut("-", modifiers: .numericPad)
                    ControllerPanelInfoDisplay(labelText: "Jump by:", data: $appState.jumpValue)
                }
                GridRow {
                    ControllerButton(buttonName: "Shuttle <", action: fileModel.videoController!.shuttleStepDown)
                        .keyboardShortcut("4", modifiers: .numericPad)
                        .keyboardShortcut(";")
                    ControllerButton(buttonName: "Stop", action: fileModel.videoController!.stop)
                        .keyboardShortcut("5", modifiers: .numericPad)
                        .keyboardShortcut(".")
                    ControllerButton(buttonName: "Shuttle >", action: fileModel.videoController!.shuttleStepUp)
                        .keyboardShortcut("6", modifiers: .numericPad)
                        .keyboardShortcut("'")
                    HStack {}
                    ControllerPanelInfoDisplay(labelText: "Frame Rate:", data: $fps, disabled: true, onChangeFunction: { _ in
                        fps = "\(fileModel.primaryVideo?.getFps() ?? 0)"
                    })
                }
                GridRow {
                    ControllerButton(buttonName: "Prev", action: fileModel.videoController!.prevFrame)
                        .keyboardShortcut("1", modifiers: .numericPad)
                        .keyboardShortcut("-")
                    ControllerButton(buttonName: "Pause", action: fileModel.videoController!.pause)
                        .keyboardShortcut("2", modifiers: .numericPad)
                        .keyboardShortcut("/")
                    ControllerButton(buttonName: "Next", action: fileModel.videoController!.nextFrame)
                        .keyboardShortcut("3", modifiers: .numericPad)
                        .keyboardShortcut("=")
                    ControllerButton(buttonName: "Find", action: fileModel.videoController!.findOnset)
                        .keyboardShortcut("+", modifiers: .numericPad)
                    ControllerPanelInfoDisplayTimestamp(labelText: "Onset:", data: $currentOnset, disabled: true)
                }
                GridRow {
                    ControllerButton(buttonName: "Add\nCell", action: fileModel.videoController!.addCell)
                        .keyboardShortcut("0", modifiers: .numericPad)
                        .keyboardShortcut("c")
                    ControllerButton(buttonName: "Set\nOffset\n+ Add", action: fileModel.videoController!.setOffsetAndAddNewCell)
                        .keyboardShortcut(".", modifiers: .numericPad)
                        .keyboardShortcut("v")
                    ControllerButton(buttonName: "Add\nCol", action: addColumn)
                        .keyboardShortcut(KeyEquivalent.return, modifiers: .numericPad)
                        .keyboardShortcut("g")
                        .sheet(isPresented: $showingColumnNameDialog) {
                            ColumnNameDialog(column: (fileModel.sheetModel.columns.last)!)
                        }
                    HStack {}
                    ControllerPanelInfoDisplayTimestamp(labelText: "Offset:", data: $currentOffset, disabled: true)
                }
            }
        }.onChange(of: fileModel.sheetModel.focusController.focusedCell) { _ in
            currentOnset = fileModel.sheetModel.focusController.focusedCell?.onset ?? 0
            currentOffset = fileModel.sheetModel.focusController.focusedCell?.offset ?? 0
        }
    }
}
