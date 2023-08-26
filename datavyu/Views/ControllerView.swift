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
                                    Controller(fileModel: fileModel, columnInFocus: columnInFocus, cellInFocus: cellInFocus, gr: gr)
                                }
                                
                            }.padding().frame(minWidth: 300)
                        }.layoutPriority(2)
                    }
                    Sheet(sheetDataModel: fileModel.sheetModel, columnInFocus: _columnInFocus, cellInFocus: _cellInFocus, temporalLayout: $temporalLayout).frame(minWidth: 600).layoutPriority(1)
                }
            
            }
    }
}
