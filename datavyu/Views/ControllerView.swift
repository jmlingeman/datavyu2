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
    @Binding var hideController: Bool
    let tabIndex: Int

    @FocusState private var columnInFocus: ColumnModel?
    @FocusState private var cellInFocus: CellModel?
    @State private var showingColumnNameDialog = false

    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack {
            ZStack {
                ForEach(fileModel.videoModels) { videoModel in
                    ZStack {}.onAppear(perform: {
                        VideoView(videoModel: videoModel, appState: appState, sheetModel: fileModel.sheetModel)
                            .openInWindow(title: videoModel.getWindowTitle(), appState: appState, sender: self, frameName: videoModel.filename)
                    })
                }
            }.onAppear(perform: {
                HStack {
                    ControllerPanelView(fileModel: fileModel).frame(alignment: .topLeading)
                    TracksStackView(fileModel: fileModel).environmentObject(appState)
                }.openInWindow(title: "Controller", appState: appState, sender: self, frameName: "controller")
            })

            Sheet(columnInFocus: _columnInFocus,
                  cellInFocus: _cellInFocus,
                  temporalLayout: $temporalLayout,
                  argumentFocusModel: ArgumentFocusModel(sheetModel: fileModel.sheetModel))
                .frame(minWidth: 600)
                .layoutPriority(1)
                .environmentObject(fileModel.sheetModel)
                .onChange(of: fileModel.sheetModel.updates) { _, _ in
                    autosaveFile(fileModel: fileModel, appState: appState, tabIndex: tabIndex)
                }
        }
    }
}
