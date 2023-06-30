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
    
    func addCode() {
        if selectedColumn != nil {
            selectedColumn!.addArgument()
        }
    }
    
    var body: some View {
        ScrollView(.vertical) {
            WrappingHStack($fileModel.sheetModel.columns) { $column in
                HStack {
                    Text(column.columnName)
                    ForEach($column.arguments) { $argument in
                        TextField(argument.name, text: $argument.name).frame(maxWidth: 100).onTapGesture {
                            selectedColumn = column
                        }
                    }
                    Button("+", action: addCode).onTapGesture {
                        selectedColumn = column
                    }
                    Spacer()
                }.padding()
            }
        }
    }
}

struct CodeEditorView_Previews: PreviewProvider {
    static var previews: some View {
        let fileModel = FileModel(sheetModel: SheetModel(sheetName: "IMG_1234"), videoModels: [VideoModel(videoFilePath: "IMG_1234")])
        CodeEditorView(fileModel: fileModel)
    }
}
