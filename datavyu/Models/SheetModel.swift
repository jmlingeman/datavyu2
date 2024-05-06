//
//  File.swift
//  sheettest
//
//  Created by Jesse Lingeman on 6/2/23.
//

import Foundation
import AppKit

final class SheetModel: ObservableObject, Identifiable, Equatable, Codable {

    
    @Published var sheetName: String
    @Published var columns: [ColumnModel]
    @Published var updates: Int = 0
    @Published var updated: Bool = false
    
    let config = Config()
    
    
    init(sheetName: String, run_setup: Bool = false) {
        self.sheetName = sheetName
        columns = [ColumnModel]()
        if run_setup {
            setup()
        }
    }
    
    static func == (lhs: SheetModel, rhs: SheetModel) -> Bool {
        return lhs.columns == rhs.columns
    }
    
    func setSelectedColumn(model: ColumnModel, suppress_update: Bool = false) {
        for column in self.columns {
            if model == column {
                column.setSelected(true)
            } else {
                column.setSelected(false)
            }
        }
        if !suppress_update {
            self.updates += 1
        }
    }
    
    func addColumn(columnName: String) {
        columns.append(ColumnModel(sheetModel: self, columnName: columnName))
    }

    func addColumn(column: ColumnModel) {
        columns.append(column)
    }
    
    func findCellIndexPath(cell_to_find: CellModel) -> IndexPath? {
        print(#function)
        for (i, column) in columns.enumerated() {
            for (j, cell) in column.getSortedCells().enumerated() {
                if cell == cell_to_find {
                    print("Found cell at \(i) \(j)")
                    return IndexPath(item: j, section: i)
                }
            }
        }
        return nil
    }
    
    func findFocusedColumn() -> ColumnModel? {
        var model: ColumnModel?
        for column in self.columns {
            print(column.isSelected)
            if column.isSelected {
                print("Setting col in focus \(column)")
                model = column
            }
        }
        return model
    }
    
    func setup() {
        let column = ColumnModel(sheetModel: self, columnName: "Test1")
        let column2 = ColumnModel(sheetModel: self, columnName: "Test2")
        addColumn(column: column)
        addColumn(column: column2)
        for _ in 1...150 {
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
    
    enum CodingKeys: CodingKey {
        case sheetName
        case columns
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sheetName = try container.decode(String.self, forKey: .sheetName)
        columns = try container.decode(Array<ColumnModel>.self, forKey: .columns)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(sheetName, forKey: .sheetName)
        try container.encode(columns, forKey: .columns)
    }
}
