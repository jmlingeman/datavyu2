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
                                                                                                    
    
    var body: some View {
        
        TabView {
            ForEach($fileController.fileModels) { $fileModel in
                DatavyuView(fileModel: fileModel).tabItem { Text(fileModel.sheetModel.sheetName) }
            }
        }
        .onAppear {
            let server = DatavyuAPIServer(fileController: fileController, port: 1312)
            server.start()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
