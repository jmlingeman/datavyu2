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
    @ObservedObject var focusController: FocusController

    @State var showingColumnNameDialog = false

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
                        ClockView(videoModel: fileModel.primaryVideo!).font(Font.system(size: Config.clockFontSize))
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
                    if !fileModel.hideTracks {
                        ControllerButton(buttonName: "Hide Tracks") {
                            fileModel.hideTracks = true
                        }
                    } else {
                        ControllerButton(buttonName: "Show Tracks") {
                            fileModel.hideTracks = false
                        }
                    }
                    ControllerButton(buttonName: "") {}.disabled(true)
                }
                GridRow {
                    ControllerButton(buttonName: "Set\nOnset", action: fileModel.videoController!.setOnset)
                        .keyboardShortcut("7", modifiers: .numericPad)
                    ControllerButton(buttonName: "Play", action: fileModel.videoController!.play)
                        .keyboardShortcut("8", modifiers: .numericPad)
                    ControllerButton(buttonName: "Set\nOffset", action: fileModel.videoController!.setOffset)
                        .keyboardShortcut("9", modifiers: .numericPad)
                    ControllerButton(buttonName: "Jump", action: { fileModel.videoController!.jump(jumpValue: appState.jumpValue) })
                        .keyboardShortcut("-", modifiers: .numericPad)
                    ControllerPanelInfoDisplay(labelText: "Jump by:", data: $appState.jumpValue)
                }
                GridRow {
                    ControllerButton(buttonName: "Shuttle <", action: fileModel.videoController!.shuttleStepDown)
                        .keyboardShortcut("4", modifiers: .numericPad)
                    ControllerButton(buttonName: "Stop", action: fileModel.videoController!.stop)
                        .keyboardShortcut("5", modifiers: .numericPad)
                    ControllerButton(buttonName: "Shuttle >", action: fileModel.videoController!.shuttleStepUp)
                        .keyboardShortcut("6", modifiers: .numericPad)
                    ControllerButton(buttonName: "Find", action: fileModel.videoController!.findOnset)
                        .keyboardShortcut("+", modifiers: .numericPad)
//                    HStack {}
                    ControllerPanelInfoDisplay(labelText: "Frame Rate:", data: $fps, disabled: true, onChangeFunction: { _ in
                        fps = "\(fileModel.primaryVideo?.getFps() ?? 0)"
                    })
                }
                GridRow {
                    ControllerButton(buttonName: "Prev", action: fileModel.videoController!.prevFrame)
                        .keyboardShortcut("1", modifiers: .numericPad)
                    ControllerButton(buttonName: "Pause", action: fileModel.videoController!.pause)
                        .keyboardShortcut("2", modifiers: .numericPad)
                    ControllerButton(buttonName: "Next", action: fileModel.videoController!.nextFrame)
                        .keyboardShortcut("3", modifiers: .numericPad)
                    HStack {}
                    ControllerPanelInfoDisplayTimestamp(labelText: "Onset:", data: $currentOnset, disabled: true)
                }
                GridRow {
                    ControllerButton(buttonName: "Set\nOffset\n+ Add", action: fileModel.videoController!.setOffsetAndAddNewCell, numColumns: 2)
                        .keyboardShortcut("0", modifiers: .numericPad).gridCellColumns(2)
                    ControllerButton(buttonName: "Set\nOffset", action: fileModel.videoController!.setOffset)
                        .keyboardShortcut(".", modifiers: .numericPad)
                    ControllerButton(buttonName: "Add\nCell", action: fileModel.videoController!.addCell)
                        .keyboardShortcut(KeyEquivalent.return, modifiers: .numericPad)
//                    HStack {}
                    ControllerPanelInfoDisplayTimestamp(labelText: "Offset:", data: $currentOffset, disabled: true)
                }
            }
        }.onChange(of: focusController.focusedCell) { _ in
            currentOnset = focusController.focusedCell?.onset ?? 0
            currentOffset = focusController.focusedCell?.offset ?? 0
        }
    }
}
