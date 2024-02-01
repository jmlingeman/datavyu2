//
//  sheettestApp.swift
//  sheettest
//
//  Created by Jesse Lingeman on 5/28/23.
//

import SwiftUI

@main
struct sheettestApp: App {
    @StateObject var fileController: FileControllerModel = FileControllerModel(fileModels: [
        FileModel(sheetModel: SheetModel(sheetName: "Test Sheet"),
                  videoModels: [
                    VideoModel(
                        videoFilePath: URL(fileURLWithPath: "/Users/jesse/Downloads/IMG_0822.MOV")),
                    VideoModel(
                        videoFilePath: URL(fileURLWithPath: "/Users/jesse/Downloads/IMG_0822.MOV")),
                    VideoModel(
                        videoFilePath: URL(fileURLWithPath: "/Users/jesse/Downloads/IMG_1234.MOV")),
                    
                  ])
    ])
    
    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(fileController).onAppear {
                ValueTransformer.setValueTransformer(TimestampTransformer(), forName: .classNameTransformerName)
            }
        }
    }
}
