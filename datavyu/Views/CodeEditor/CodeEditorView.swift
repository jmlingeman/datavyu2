//
//  CodeEditorView.swift
//  datavyu
//
//  Created by Jesse Lingeman on 6/4/23.
//

import SwiftUI
import WrappingHStack

struct CodeEditorView: View {
    @ObservedObject var fileModel: FileModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView(.vertical) {
            Text("Code Editor").font(.system(size: 30)).frame(alignment: .topLeading).padding()
            WrappingHStack(fileModel.sheetModel.columns, id: \.self) { column in
                CodeEditorRow(column: column)
            }
            Button("Close") {
                dismiss()
                fileModel.sheetModel.updates += 1 // Force sheet update when we close
            }.padding()
        }
    }
}

struct CodeEditorView_Previews: PreviewProvider {
    static var previews: some View {
        let fileModel = FileModel(sheetModel: SheetModel(sheetName: "IMG_1234"), videoModels: [VideoModel(videoFilePath: "IMG_1234")])
        CodeEditorView(fileModel: fileModel)
    }
}
