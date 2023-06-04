//
//  ColumnModel.swift
//  sheettest
//
//  Created by Jesse Lingeman on 6/2/23.
//

import Foundation

class ColumnModel: ObservableObject, Identifiable, Equatable, Hashable {
    @Published var columnName: String
    @Published var cells: [CellModel]
    
    static func == (lhs: ColumnModel, rhs: ColumnModel) -> Bool {
        if(lhs.columnName == rhs.columnName) {
            return true
        }
        return false
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(columnName)
    }
    
    init(columnName: String) {
        self.columnName = columnName
        self.cells = Array<CellModel>()
    }
    
    func addCell(cell: CellModel) -> ColumnModel {
        cell.ordinal = self.cells.count + 1
        self.cells.append(cell)
        return self
    }
}
