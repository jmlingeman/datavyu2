//
//  ColumnNameDialog.swift
//  datavyu
//
//  Created by Jesse Lingeman on 7/2/23.
//

import SwiftUI

struct ColumnNameDialog: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var column: ColumnModel

    @FocusState private var focusedField: Bool
    @State private var nameIsOK: Bool = true

    func submit() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            column.sheetModel?.updateArgumentNames() // hack to force update of name TODO: why?
            column.sheetModel?.updateSheet()
        }
        dismiss()
    }

    var body: some View {
        VStack {
            Text("Enter new column name").font(.system(size: 20)).frame(alignment: .topLeading).padding()
            HStack {
                TextField("Column Name", text: $column.columnName).onSubmit {
                    dismiss()
                }.focused($focusedField, equals: true)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            focusedField = true
                        }
                    }
                    .onChange(of: column.columnName, perform: { _ in
                        if column.sheetModel?.checkNewColumnName(column: column) == false {
                            nameIsOK = false
                        } else {
                            nameIsOK = true
                        }
                    })
                    .onSubmit {
                        if nameIsOK {
                            submit()
                        }
                    }
//                    .onKeyPress(KeyEquivalent.return) {
//                        if nameIsOK {
//                            submit()
//                        }
//                        return KeyPress.Result.handled
//                    }
            }.padding()
            Text("Error: Column is blank or name already exists").opacity(nameIsOK ? 0 : 1)
            HStack {
                Button("OK") {
                    if nameIsOK {
                        submit()
                    }
                }.disabled(!nameIsOK)
            }.padding()
        }.padding()
    }
}
