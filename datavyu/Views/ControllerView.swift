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
    @StateObject var videoModel = VideoModel(videoFilePath: "IMG_1234")
    @StateObject var sheetModel = SheetModel(sheetName: "IMG_1234")

    @FocusState private var columnInFocus: ColumnModel?

    func play() {
        videoModel.play()
    }

    func stop() {
        videoModel.stop()
    }

    func nextFrame() {
        videoModel.nextFrame()
    }

    func prevFrame() {
        videoModel.prevFrame()
    }

    func addCol() {
        let columnModel = ColumnModel(columnName: "test4444")
        let _ = columnModel.addCell()
        let _ = columnModel.addCell()
        sheetModel.addColumn(column: columnModel)
    }

    func addCell() {
        let cell = columnInFocus?.addCell()
        if cell != nil {
            cell?.setOnset(onset: videoModel.currentTime)
        }
        sheetModel.updates += 1 // Force sheetmodel updates of nested objects
    }

    var body: some View {
        HStack {
            Grid {
                GridRow {
                    VideoView(videoModel: videoModel)
                }
                GridRow {
                    Text("\($videoModel.currentTime.wrappedValue)")
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
            Sheet(sheetDataModel: sheetModel, columnInFocus: _columnInFocus)
        }
    }
}

struct ControllerView_Previews: PreviewProvider {
    static var previews: some View {
        ControllerView()
    }
}
