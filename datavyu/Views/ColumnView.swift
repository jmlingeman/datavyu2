//
//  ColumnView.swift
//  sheettest
//
//  Created by Jesse Lingeman on 6/2/23.
//

import SwiftUI
import WrappingHStack
import TimecodeKit

struct Column: View, Hashable {
    
    @ObservedObject var columnDataModel: ColumnModel
    @FocusState private var isFocused: Bool
    
    static func == (lhs: Column, rhs: Column) -> Bool {
        if(lhs.columnDataModel.columnName == rhs.columnDataModel.columnName) {
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
            ForEach(self.columnDataModel.cells) { cell in
                Cell(cellDataModel: cell, isEditing: $isFocused)
            }
        }
    }
}

struct Column_Previews: PreviewProvider {
    
    static var previews: some View {
        let columnModel = ColumnModel(columnName: "Test Column");
        Column(columnDataModel: columnModel)
    }
}
