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
    @ObservedObject var fileModel: FileModel
    @FocusState private var columnInFocus: ColumnModel?
    @FocusState private var cellInFocus: CellModel?

    func play() {
        for videoModel in fileModel.videoModels {
            videoModel.play()
        }
    }

    func stop() {
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

    func addCol() {
        let columnModel = ColumnModel(columnName: "test4444")
        let _ = columnModel.addCell()
        let _ = columnModel.addCell()
        fileModel.sheetModel.addColumn(column: columnModel)
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

    var body: some View {
            VStack {
                HSplitView {
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
                                Button("Prev", action: prevFrame).keyboardShortcut("q", modifiers: [])
                                Button("Play", action: play).keyboardShortcut("p", modifiers: [])
                                Button("Stop", action: stop).keyboardShortcut("s", modifiers: [])
                                Button("Next", action: nextFrame).keyboardShortcut("w", modifiers: [])
                            }
                        }
                        GridRow {
                            HStack {
                                Button("Add Col", action: addCol).keyboardShortcut("c", modifiers: [])
                                Button("Add Cell", action: addCell).keyboardShortcut("v", modifiers: [])
                            }
                        }
                        GridRow {
                            HStack {
                                Button("Set Onset", action: setOnset).keyboardShortcut("j", modifiers: [])
                                Button("Set Offset", action: setOffset).keyboardShortcut("k", modifiers: [])
                                Button("Set Offset + Add", action: setOffsetAndAddNewCell).keyboardShortcut("l", modifiers: [])

                            }
                        }
                    }
                    Sheet(sheetDataModel: fileModel.sheetModel, columnInFocus: _columnInFocus, cellInFocus: _cellInFocus)
                }
            
        }
    }
}

struct ControllerView_Previews: PreviewProvider {
    static var previews: some View {
        let fileModel = FileModel(sheetModel: SheetModel(sheetName: "IMG_1234"), videoModels: [VideoModel(videoFilePath: "IMG_1234")])
        ControllerView(fileModel: fileModel)
    }
}
