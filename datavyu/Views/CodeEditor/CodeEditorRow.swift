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
    var codeRow: CodeRowTextFieldView

    init(column: ColumnModel, selectedArgument: SelectedArgument) {
        self.column = column
        self.selectedArgument = selectedArgument
        codeRow = CodeRowTextFieldView(column: column, selectedArgument: selectedArgument)
    }

    var body: some View {
        VStack {
            HStack {
                codeRow.onChange(of: column.reorderCount) { oldValue, newValue in
                    if oldValue < newValue {
                        codeRow.selectArgument(idx: selectedArgument.argumentIdx! + 1)
                    } else {
                        codeRow.selectArgument(idx: selectedArgument.argumentIdx! - 1)
                    }
                }
                CodeEditorAddCodeButton(column: column)
                CodeEditorRemoveCodeButton(column: column)
                Spacer()
            }
        }
    }
}
