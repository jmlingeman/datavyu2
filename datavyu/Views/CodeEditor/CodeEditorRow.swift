//
//  CodeEditorRow.swift
//  datavyu
//
//  Created by Jesse Lingeman on 7/1/23.
//

import SwiftUI

struct CodeEditorRow: View {
    @ObservedObject var column: ColumnModel
    @State var selectedArgument: Argument?

    var body: some View {
        VStack {
            HStack {
                EditableLabel($column.columnName)
//                WrappedHStack($column.arguments) { $argument in
//                    TextField(argument.name, text: $argument.name)
//                        .frame(maxWidth: 100)
//                        .padding()
//                }.border(Color.primary, width: 2)
                CodeRowTextFieldView(column: column)

                CodeEditorAddCodeButton(column: column)
                CodeEditorRemoveCodeButton(column: column)
                Spacer()
            }
            HStack {
                Spacer()
//                CodeEditorMoveCodeButton(column: column, direction: "left", code: selectedArgument)
//                CodeEditorMoveCodeButton(column: column)
            }
        }
    }
}
