//
//  ContentView.swift
//  sheettest
//
//  Created by Jesse Lingeman on 5/28/23.
//

import SwiftUI
import WrappingHStack


struct ContentView: View {
    @EnvironmentObject var fileController: FileControllerModel
    @State var selectedTab = 0

    
    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(Array(zip(fileController.fileModels.indices, $fileController.fileModels)), id: \.0) { idx, $fileModel in
                DatavyuView(fileModel: fileModel).tabItem { Text(fileModel.sheetModel.sheetName) }
                    .environmentObject(fileModel.sheetModel).tag(idx)
            }
        }
        .onAppear {
            let server = DatavyuAPIServer(fileController: fileController, port: 1312)
            server.start()
        }
        .onChange(of: fileController.activeFileModel) { oldValue, newValue in
            let newTabIdx = fileController.fileModels.firstIndex(of: newValue)
            selectedTab = newTabIdx ?? 0
        }
        
    }
}
