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
    
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack {
            ZStack {
                ForEach(fileModel.videoModels) { videoModel in
                    ZStack {}.onAppear(perform: {
                        VideoView(videoModel: videoModel, sheetModel: fileModel.sheetModel)
                            .openInWindow(title: videoModel.filename, appState: appState, sender: self, frameName: videoModel.filename)
                    })
                }
            }.onAppear(perform: {
                HStack {
                    ControllerPanelView(fileModel: fileModel, columnInFocus: _columnInFocus, cellInFocus: _cellInFocus).frame(alignment: .topLeading)
                    TracksStackView(fileModel: fileModel)
                }.openInWindow(title: "Controller", appState: appState, sender: self, frameName: "controller")
            })

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
