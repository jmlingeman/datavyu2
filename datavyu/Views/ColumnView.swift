//
//  ColumnView.swift
//  sheettest
//
//  Created by Jesse Lingeman on 6/2/23.
//

import SwiftUI
import TimecodeKit

struct Column: View, Hashable {
    @ObservedObject var columnDataModel: ColumnModel
    @FocusState private var isFocused: Bool

    static func == (lhs: Column, rhs: Column) -> Bool {
        if lhs.columnDataModel.columnName == rhs.columnDataModel.columnName {
            return true
        }
        return false
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(columnDataModel.columnName)
    }

    init(columnDataModel: ColumnModel) {
        self.columnDataModel = columnDataModel
    }

    var body: some View {
        VStack {
            Text(columnDataModel.columnName)
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .background(isFocused ? Color.blue : Color.black)
                .frame(height: 30)
            ForEach(columnDataModel.cells) { cell in
                Cell(cellDataModel: cell, isEditing: $isFocused)
            }
            Spacer()
        }
    }
}

struct Column_Previews: PreviewProvider {
    static var previews: some View {
        Column(columnDataModel: ColumnModel(columnName: "Test Column"))
    }
}
