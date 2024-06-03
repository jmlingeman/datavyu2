//
//  ControllerPanelView.swift
//  datavyu
//
//  Created by Jesse Lingeman on 8/26/23.
//

import SwiftUI

struct ControllerPanelView: View {
    @ObservedObject var fileModel: FileModel
    @FocusState var columnInFocus: ColumnModel?
    @FocusState var cellInFocus: CellModel?

    @State var showingColumnNameDialog = false
    @State var jumpValue: String = "00:00:05:000"

    func play() {
        for videoModel in fileModel.videoModels {
            videoModel.play()
        }
    }

    func stepFrame(reverse: Bool = false) {
        var highestFps: Float = -1.0
        var highestFpsVideo: VideoModel?

        for videoModel in fileModel.videoModels {
            let fps = videoModel.getFps()
            if fps > highestFps {
                highestFps = fps
                highestFpsVideo = videoModel
            }
        }

        if !reverse {
            highestFpsVideo?.nextFrame()
        } else {
            highestFpsVideo?.prevFrame()
        }

        for videoModel in fileModel.videoModels {
            if videoModel == highestFpsVideo {
                continue
            }

            videoModel.seek(to: highestFpsVideo!.currentTime)
        }
    }

    func nextFrame() {
        stepFrame()
    }

    func prevFrame() {
        stepFrame(reverse: true)
    }

    func jump() {
        fileModel.seekAllVideos(to: fileModel.currentTime() + Double(timestringToSecondsDouble(timestring: jumpValue)))
    }

    func findOnset() {
        if fileModel.sheetModel.selectedCell != nil {
            find(value: millisToSeconds(millis: fileModel.sheetModel.selectedCell!.onset))
        }
    }

    func findOffset() {
        if fileModel.sheetModel.selectedCell != nil {
            find(value: millisToSeconds(millis: fileModel.sheetModel.selectedCell!.offset))
        }
    }

    func find(value: Double) {
        fileModel.seekAllVideos(to: value)
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

    func addColumn() {
        let columnModel = ColumnModel(sheetModel: fileModel.sheetModel, columnName: "Column\(fileModel.sheetModel.columns.count + 1)")
        fileModel.sheetModel.addColumn(column: columnModel)
        columnInFocus = columnModel

        fileModel.sheetModel.setSelectedColumn(model: columnModel)

        showingColumnNameDialog.toggle()
    }

    func addCell() {
        let model = fileModel.sheetModel.findFocusedColumn()

        let cell = model?.addCell()
        fileModel.sheetModel.setSelectedCell(selectedCell: cell)
        if cell != nil {
            cell?.setOnset(onset: fileModel.primaryVideo?.currentTime ?? 0)
        }
        fileModel.sheetModel.updates += 1 // Force sheetmodel updates of nested objects
    }

    func setOnset() {
        fileModel.sheetModel.selectedCell?.setOnset(onset: fileModel.currentTime())
    }

    func setOffset() {
        fileModel.sheetModel.selectedCell?.setOffset(offset: fileModel.currentTime())
    }

    func setOffsetAndAddNewCell() {
        fileModel.sheetModel.selectedCell?.setOffset(offset: fileModel.currentTime())
        let cell = columnInFocus?.addCell()
        cell?.setOnset(onset: fileModel.currentTime() + 1)
        fileModel.sheetModel.setSelectedCell(selectedCell: cell)

        fileModel.sheetModel.updates += 1
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
                    ControllerButton(buttonName: "Set\nOnset", action: setOnset)
                        .keyboardShortcut("7", modifiers: .numericPad)
                        .keyboardShortcut("[")
                    ControllerButton(buttonName: "Play", action: play)
                        .keyboardShortcut("8", modifiers: .numericPad)
                        .keyboardShortcut(",")
                    ControllerButton(buttonName: "Set\nOffset", action: setOffset)
                        .keyboardShortcut("9", modifiers: .numericPad)
                        .keyboardShortcut("]")
                    ControllerButton(buttonName: "Jump", action: jump)
                        .keyboardShortcut("-", modifiers: .numericPad)
                }
                GridRow {
                    ControllerButton(buttonName: "Shuttle <", action: shuttleStepDown)
                        .keyboardShortcut("4", modifiers: .numericPad)
                        .keyboardShortcut(";")
                    ControllerButton(buttonName: "Stop", action: stop)
                        .keyboardShortcut("5", modifiers: .numericPad)
                        .keyboardShortcut(".")
                    ControllerButton(buttonName: "Shuttle >", action: shuttleStepUp)
                        .keyboardShortcut("6", modifiers: .numericPad)
                        .keyboardShortcut("'")
                    ControllerButton(buttonName: "Find", action: findOnset)
                        .keyboardShortcut("+", modifiers: .numericPad)
                }
                GridRow {
                    ControllerButton(buttonName: "Prev", action: prevFrame)
                        .keyboardShortcut("1", modifiers: .numericPad)
                        .keyboardShortcut("-")
                    ControllerButton(buttonName: "Pause", action: pause)
                        .keyboardShortcut("2", modifiers: .numericPad)
                        .keyboardShortcut("/")
                    ControllerButton(buttonName: "Next", action: nextFrame)
                        .keyboardShortcut("3", modifiers: .numericPad)
                        .keyboardShortcut("=")
                    TextField("Jump by", text: $jumpValue).frame(width: 100)
                }
                GridRow {
                    ControllerButton(buttonName: "Add\nCell", action: addCell)
                        .keyboardShortcut("0", modifiers: .numericPad)
                        .keyboardShortcut("c")
                    ControllerButton(buttonName: "Set\nOffset\n+ Add", action: setOffsetAndAddNewCell)
                        .keyboardShortcut(".", modifiers: .numericPad)
                        .keyboardShortcut("v")
                    ControllerButton(buttonName: "Add\nCol", action: addColumn)
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
