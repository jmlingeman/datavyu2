//
//  ControllerView.swift
//  sheettest
//
//  Created by Jesse Lingeman on 6/3/23.
//

import SwiftUI
import CoreMedia
import AVKit

struct ControllerView: View {
    
    @StateObject var videoModel = VideoModel(videoFilePath: "IMG_1234")
    @StateObject var sheetModel = SheetModel(sheetName: "IMG_1234")
    
    @FocusState private var columnInFocus: ColumnModel?
    
    let player = AVPlayer(url: Bundle.main.url(forResource: "IMG_1234", withExtension: "MOV")!)
    
    func play() {
        player.play()
    }
    
    func stop() {
        player.pause()
    }
    
    func nextFrame() {
        player.currentItem!.step(byCount: 1)
    }
    
    func prevFrame() {
        player.currentItem!.step(byCount: -1)
    }
    
    func addCol() {
        let columnModel = ColumnModel(columnName: "test4444")
        columnModel.addCell(cell: CellModel())
        columnModel.addCell(cell: CellModel())
        sheetModel.addColumn(column: columnModel)
    }
    
    func addCell() {
        let cell = CellModel()
        cell.setOnset(onset: videoModel.currentTime)
        columnInFocus?.addCell(cell: cell)
    }
    
    var body: some View {
        HStack {
            Grid {
                GridRow {
                    VideoView(player: player, videoModel: videoModel)
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
