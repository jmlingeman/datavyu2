//
//  ContentView.swift
//  sheettest
//
//  Created by Jesse Lingeman on 5/28/23.
//

import SwiftUI
import WrappingHStack

struct ContentView: View {
    @StateObject private var fileModel = FileModel(sheetModel: SheetModel(sheetName: "IMG_1234"), videoModels: [VideoModel(videoFilePath: "IMG_1234"), VideoModel(videoFilePath: "IMG_1234")])
    @StateObject var server = FileServer(port: 1312)

    
    var body: some View {
        HStack {
            DatavyuView(fileModel: fileModel).onAppear {
                server.start()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
