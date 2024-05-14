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
            GeometryReader { gr in
                ZStack {
                    ForEach(fileModel.videoModels) { videoModel in
                        ZStack {}.onAppear(perform: {
                            VideoView(videoModel: videoModel).openInWindow(title: videoModel.filename, sender: self, frameName: videoModel.filename)
                        })
                    }
                }.onAppear(perform: {
                    HStack {
                        ControllerPanelView(fileModel: fileModel, gr: gr, columnInFocus: _columnInFocus, cellInFocus: _cellInFocus)
                        TracksStackView(fileModel: fileModel)
                    }.openInWindow(title: "Controller", sender: self, frameName: "controller")
                })
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
