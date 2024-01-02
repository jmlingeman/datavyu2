//
//  File.swift
//  sheettest
//
//  Created by Jesse Lingeman on 6/2/23.
//

import Foundation
import AppKit

class SheetModel: ObservableObject, Identifiable {
    @Published var sheetName: String
    @Published var columns: [ColumnModel]
    @Published var updates: Int = 0
    @Published var updated: Bool = false
    
    let config = Config()
    
    
    init(sheetName: String) {
        self.sheetName = sheetName
        columns = [ColumnModel]()
        setup()
    }

    func addColumn(column: ColumnModel) {
        columns.append(column)
    }
    
    func setup() {
        let column = ColumnModel(columnName: "Test1")
        let column2 = ColumnModel(columnName: "Test2")
        addColumn(column: column)
        addColumn(column: column2)
        for k in 1...1500 {
            let _ = column.addCell()
        }
        let _ = column2.addCell()
    }
    
    func setColumn(column: ColumnModel) {
        DispatchQueue.main.async {
            let colIdx = self.columns.firstIndex(where: { c in
                c.columnName == column.columnName
            })
            
            if colIdx == nil {
                self.addColumn(column: column)
            } else {
                self.columns[colIdx!] = column
                self.updates += 1
            }
        }

    }
}
