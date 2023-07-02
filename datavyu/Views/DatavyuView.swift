//
//  DatavyuView.swift
//  datavyu
//
//  Created by Jesse Lingeman on 7/1/23.
//

import SwiftUI

struct DatavyuView: View {
    @ObservedObject var fileModel: FileModel
    @State private var showingSheet = false
    
    var body: some View {
        ZStack {
            GeometryReader { gr in
                ControllerView(fileModel: fileModel)
                    .toolbar {
                        ToolbarItemGroup {
                            Button("Code Editor") {
                                showingSheet.toggle()
                            }
                            .sheet(isPresented: $showingSheet) {
                                CodeEditorView(fileModel: fileModel).frame(width: gr.size.width / 2, height: gr.size.height / 2)
                            }
                        }
                    }
            }
        }
        
    }
}

struct DatavyuView_Previews: PreviewProvider {
    static var previews: some View {
        let fileModel = FileModel(sheetModel: SheetModel(sheetName: "IMG_1234"), videoModels: [VideoModel(videoFilePath: "IMG_1234")])

        DatavyuView(fileModel: fileModel)
    }
}
