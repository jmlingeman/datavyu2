//
//  CodeEditorRow.swift
//  datavyu
//
//  Created by Jesse Lingeman on 7/1/23.
//

import SwiftUI
import SwiftUIReorderableForEach

struct CodeEditorRow: View {
    @ObservedObject var column: ColumnModel
    
    var body: some View {
        HStack {
            EditableLabel($column.columnName)
            ForEach($column.arguments) { $argument in
                TextField(argument.name, text: $argument.name).frame(maxWidth: 100).padding().border(Color.black, width: 5)
            }
            CodeEditorAddCodeButton(column: column)
            CodeEditorRemoveCodeButton(column: column)
            Spacer()
        }.padding()
    }
}

struct CodeEditorRow_Previews: PreviewProvider {
    static var previews: some View {
        let c = ColumnModel(columnName: "test1")
        CodeEditorRow(column: c)
    }
}
