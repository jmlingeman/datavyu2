//
//  DatavyuView.swift
//  datavyu
//
//  Created by Jesse Lingeman on 7/1/23.
//

import SwiftUI

struct DatavyuView: View {
    @State var fileModel: FileModel
    @State private var showingCodeEditor = false
    @State private var showingOptions = false
    
    var body: some View {
        ZStack {
            GeometryReader { gr in
                ControllerView(fileModel: fileModel)
                    .toolbar {
                        ToolbarItemGroup {
                            Button("Code Editor") {
                                showingCodeEditor.toggle()
                            }
                            .sheet(isPresented: $showingCodeEditor) {
                                CodeEditorView(fileModel: fileModel).frame(width: gr.size.width / 2, height: gr.size.height / 2)
                            }
                            Button("Options") {
                                showingOptions.toggle()
                            }
                            .sheet(isPresented: $showingOptions) {
                                OptionsView().frame(width: gr.size.width / 2, height: gr.size.height / 2)
                            }
                            Button("Open File")
                            {
                                let panel = NSOpenPanel()
                                panel.allowsMultipleSelection = false
                                panel.canChooseDirectories = false
                                if panel.runModal() == .OK {
                                    fileModel = parseDbFile(fileUrl: panel.url!)
                                }
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
