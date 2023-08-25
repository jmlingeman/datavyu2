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
                                        Button("Set Onset", action: setOnset).keyboardShortcut("j", modifiers: [])
                                        Button("Play", action: play).keyboardShortcut("p", modifiers: [])
                                        Button("Set Offset", action: setOffset).keyboardShortcut("k", modifiers: [])
                                    }
                                }
                                GridRow {
                                    HStack {
                                        Button("Shuttle <", action: shuttleStepDown).keyboardShortcut("s", modifiers: [])
                                        Button("Stop", action: stop).keyboardShortcut("s", modifiers: [])
                                        Button("Shuttle >", action: shuttleStepUp).keyboardShortcut("s", modifiers: [])
                                        
                                    }
                                }
                                GridRow {
                                    HStack {
                                        Button("Prev", action: prevFrame).keyboardShortcut("q", modifiers: [])
                                        Button("Pause", action: pause).keyboardShortcut("s", modifiers: [])
                                        Button("Next", action: nextFrame).keyboardShortcut("w", modifiers: [])
                                        
                                    }
                                }
                                GridRow {
                                    HStack {
                                        Button("Add Cell", action: addCell).keyboardShortcut("v", modifiers: [])
                                        Button("Set Offset + Add", action: setOffsetAndAddNewCell).keyboardShortcut("l", modifiers: [])
                                        Button("Add Col", action: addColumn)
                                            .keyboardShortcut("c", modifiers: [])
                                            .sheet(isPresented: $showingColumnNameDialog) {
                                                ColumnNameDialog(column: (columnInFocus ?? fileModel.sheetModel.columns.last)!)
                                        }
                                        Button("Add Video", action: addVideo).keyboardShortcut("c", modifiers: [])
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
