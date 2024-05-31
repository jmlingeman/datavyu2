//
//  CodeEditorView.swift
//  datavyu
//
//  Created by Jesse Lingeman on 6/4/23.
//

import SwiftUI
import WrappingHStack

struct CodeEditorView: View {
    @ObservedObject var sheetModel: SheetModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ScrollView(.vertical) {
            Text("Code Editor").font(.system(size: 30)).frame(alignment: .topLeading).padding()
            WrappingHStack(sheetModel.columns, id: \.self) { column in
                CodeEditorRow(column: column)
            }
            Button("Add Column") {
                sheetModel.addColumn(columnName: sheetModel.getNextDefaultColumnName())
            }
            Button("Close") {
                dismiss()
                sheetModel.updateArgumentNames()
                sheetModel.updateSheet() // Force sheet update when we close
            }.padding()
        }
    }
}
