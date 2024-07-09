//
//  DatavyuView.swift
//  datavyu
//
//  Created by Jesse Lingeman on 7/1/23.
//

import SwiftUI

struct DatavyuView: View {
    @ObservedObject var fileModel: FileModel

    @Binding var temporalLayout: Bool
    @Binding var hideController: Bool

    let tabIndex: Int

    @EnvironmentObject var fileController: FileControllerModel
    @Environment(\.undoManager) var undoManager

    var body: some View {
        ZStack {
            GeometryReader { _ in
                ControllerView(fileModel: fileModel, temporalLayout: $temporalLayout, hideController: $hideController, tabIndex: tabIndex)
                    .onAppear(perform: {
                        fileModel.sheetModel.setUndoManager(undoManager: undoManager!)
                    })
                    .environmentObject(fileModel.sheetModel)
                    .environmentObject(fileModel)
            }
        }
    }
}
