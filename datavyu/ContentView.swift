//
//  ContentView.swift
//  sheettest
//
//  Created by Jesse Lingeman on 5/28/23.
//

import SwiftUI
import WrappingHStack

struct ContentView: View {
    @StateObject var fileModel = FileModel(sheetModel: SheetModel(sheetName: "IMG_1234"),
                                           videoModels: [
                                                VideoModel(
                                                    videoFilePath: URL(fileURLWithPath: "/Users/jesse/Downloads/IMG_0822.MOV")),
                                                VideoModel(
                                                    videoFilePath: URL(fileURLWithPath: "/Users/jesse/Downloads/IMG_0822.MOV"))])
    var server = FileServer(port: 1312)

                                                                                                    
    
    var body: some View {
        HStack {
            DatavyuView(fileModel: fileModel).onAppear {
                server.start(fileModel: fileModel)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
