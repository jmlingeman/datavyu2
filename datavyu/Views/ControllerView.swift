//
//  ControllerView.swift
//  sheettest
//
//  Created by Jesse Lingeman on 6/3/23.
//

import SwiftUI

struct ControllerView: View {
    @ObservedObject var fileModel: FileModel
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
                                    ControllerPanelView(fileModel: fileModel, gr: gr, columnInFocus: _columnInFocus, cellInFocus: _cellInFocus)
                                }
                                
                            }.padding().frame(minWidth: 300)
                        }.layoutPriority(2)
                    }
                    Sheet(columnInFocus: _columnInFocus,
                          cellInFocus: _cellInFocus,
                          temporalLayout: $temporalLayout,
                          argumentFocusModel: ArgumentFocusModel(sheetModel: fileModel.sheetModel))
                    .frame(minWidth: 600)
                    .layoutPriority(1)
                    .environmentObject(fileModel.sheetModel)
                }
            
            }
    }
}


