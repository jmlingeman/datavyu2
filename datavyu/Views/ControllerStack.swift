//
//  ControllerStack.swift
//  sheettest
//
//  Created by Jesse Lingeman on 6/3/23.
//

import SwiftUI

struct ControllerStack: View {
    @ObservedObject var fileModel: FileModel
    @State private var showingTracks = true
    @EnvironmentObject private var appState: AppState

    var body: some View {
        HStack {
            ControllerPanelView(fileModel: fileModel, appState: appState, focusController: fileModel.sheetModel.focusController).frame(alignment: .topLeading)
            TracksStackView(fileModel: fileModel).environmentObject(appState).isHidden(!showingTracks, remove: true)
        }.onChange(of: fileModel.hideTracks) { _ in
            showingTracks = !fileModel.hideTracks
        }
    }
}
