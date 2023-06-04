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
            Text(self.columnDataModel.columnName)
            ForEach(self.columnDataModel.cells) { cell in
                Cell(cellDataModel: cell)
            }
        }
    }
}

struct Column_Previews: PreviewProvider {
    static var previews: some View {
        let cell = CellModel()
        let columnModel = ColumnModel(columnName: "Test Column").addCell(cell: cell)
        Column(columnDataModel: columnModel)
    }
}
