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
        if lhs.columnName == rhs.columnName {
            return true
        }
        return false
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(columnName)
    }

    init(columnName: String) {
        self.columnName = columnName
        cells = [CellModel]()
    }

    func addCell(cell: CellModel) {
        cell.ordinal = cells.count + 1
        cells.append(cell)
    }
}
