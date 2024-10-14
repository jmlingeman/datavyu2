//
//  CodeEditorRow.swift
//  datavyu
//
//  Created by Jesse Lingeman on 7/1/23.
//

import SwiftUI

struct CodeEditorRow: View {
    @ObservedObject var column: ColumnModel
    @ObservedObject var selectedArgument: SelectedArgument
    @State var oldValue = 0
    var codeRow: CodeRowTextFieldView

    init(column: ColumnModel, selectedArgument: SelectedArgument) {
        self.column = column
        self.selectedArgument = selectedArgument
        codeRow = CodeRowTextFieldView(column: column, selectedArgument: selectedArgument)
    }

    var body: some View {
        VStack {
            HStack {
                codeRow
                CodeEditorAddCodeButton(column: column)
                CodeEditorRemoveCodeButton(column: column)
                Spacer()
            }
        }
    }
}
