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
    @State var selectedColumn: ColumnModel?
    
    var body: some View {
        VStack {
            WrappingHStack($fileModel.sheetModel.columns) { $column in
                CodeEditorRow(column: column)
            }
        }.padding()
    }
}

struct CodeEditorView_Previews: PreviewProvider {
    static var previews: some View {
        let fileModel = FileModel(sheetModel: SheetModel(sheetName: "IMG_1234"), videoModels: [VideoModel(videoFilePath: "IMG_1234")])
        CodeEditorView(fileModel: fileModel)
    }
}
