//
//  File.swift
//  sheettest
//
//  Created by Jesse Lingeman on 6/2/23.
//

import Foundation

class SheetModel: ObservableObject, Identifiable {
    @Published var sheetName: String
    @Published var columns: [ColumnModel]
    
    init(sheetName: String) {
        self.sheetName = sheetName
        self.columns = Array<ColumnModel>()
        self.setup()
    }
    
    func addColumn(column: ColumnModel) -> Void {
        self.columns.append(column)
    }
    
    func setup() {
        let column = ColumnModel(columnName: "Test1")
        let column2 = ColumnModel(columnName: "Test2")
        addColumn(column: column)
        addColumn(column: column2)
        column.addCell(cell: CellModel())
        column2.addCell(cell: CellModel())
    }
}
