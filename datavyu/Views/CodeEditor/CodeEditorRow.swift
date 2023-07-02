//
//  CodeEditorRow.swift
//  datavyu
//
//  Created by Jesse Lingeman on 7/1/23.
//

import SwiftUI

struct CodeEditorRow: View {
    @ObservedObject var column: ColumnModel
    
    var body: some View {
        HStack {
            EditableLabel($column.columnName)
            ForEach($column.arguments) { $argument in
                TextField(argument.name, text: $argument.name).frame(maxWidth: 100)
            }
            CodeEditorAddCodeButton(column: column)
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
