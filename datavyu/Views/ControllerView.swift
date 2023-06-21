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
    @StateObject var fileModel: FileModel
    
    @FocusState private var columnInFocus: ColumnModel?

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
            cell?.setOnset(onset: fileModel.primaryVideo()?.currentTime ?? 0)
        }
        fileModel.sheetModel.updates += 1 // Force sheetmodel updates of nested objects
    }

    var body: some View {
        HStack {
            Grid {
                ForEach(fileModel.videoModels) { videoModel in
                    GridRow {
                        VideoView(videoModel: videoModel)
                    }
                }
                ForEach(fileModel.videoModels) { videoModel in
                    GridRow {
                        TracksStackView(videoModel: videoModel)
                    }
                }
                ForEach(fileModel.videoModels) { videoModel in
                    ClockView(videoModel: videoModel)
                }
                GridRow {
                    Button("Play", action: play).keyboardShortcut("p", modifiers: [])
                    Button("Stop", action: stop).keyboardShortcut("s", modifiers: [])
                }
                GridRow {
                    Button("Next", action: nextFrame).keyboardShortcut("w", modifiers: [])
                    Button("Prev", action: prevFrame).keyboardShortcut("q", modifiers: [])
                    Button("Add Col", action: addCol).keyboardShortcut("c", modifiers: [])
                    Button("Add Cell", action: addCell).keyboardShortcut("c", modifiers: [])
                }
            }
            Sheet(sheetDataModel: fileModel.sheetModel, columnInFocus: _columnInFocus)
        }
    }
}

struct ControllerView_Previews: PreviewProvider {
    static var previews: some View {
        let fileModel = FileModel(sheetModel: SheetModel(sheetName: "IMG_1234"), videoModels: [VideoModel(videoFilePath: "IMG_1234")])
        ControllerView(fileModel: fileModel)
    }
}
