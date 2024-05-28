//
//  SheetModel.swift
//  sheettest
//
//  Created by Jesse Lingeman on 6/2/23.
//

import AppKit
import Foundation

final class SheetModel: ObservableObject, Identifiable, Equatable, Codable {
    @Published var sheetName: String
    @Published var columns: [ColumnModel]
    @Published var visibleColumns: [ColumnModel]
    @Published var updates: Int = 0
    @Published var updated: Bool = false
    var selectedCell: CellModel?

    let config = Config()
    var undoManager: UndoManager?

    init(sheetName: String, run_setup: Bool = false) {
        self.sheetName = sheetName
        columns = [ColumnModel]()
        visibleColumns = [ColumnModel]()
        if run_setup {
            setup()
        }
    }

    static func == (lhs: SheetModel, rhs: SheetModel) -> Bool {
        lhs.columns == rhs.columns
    }

    func setUndoManager(undoManager: UndoManager) {
        self.undoManager = undoManager

        for column in columns {
            column.setUndoManager(undoManager: undoManager)
        }
    }

    func setVisibleColumns() {
        visibleColumns = columns.filter { c in
            !c.hidden
        }
    }

    func setSelectedColumn(model: ColumnModel, suppress_update: Bool = false) {
        print("Setting column \(model.columnName) to selected")
        for column in columns {
            if model == column {
                column.isSelected = true
            } else {
                column.isSelected = false
            }
        }
        if !suppress_update {
            updates += 1
        }
    }

    func copy() -> SheetModel {
        let newSheetModel = SheetModel(sheetName: sheetName)
        newSheetModel.columns = columns.map { c in
            c.copy(sheetModelCopy: newSheetModel)
        }
        newSheetModel.updates = updates

        return newSheetModel
    }

    func updateArgumentNames() {
        for column in columns {
            for cell in column.cells {
                cell.updateArgumentNames()
            }
        }
    }

    func addColumn(columnName: String) -> ColumnModel {
        return addColumn(column: ColumnModel(sheetModel: self, columnName: columnName))
    }

    func addColumn(column: ColumnModel) -> ColumnModel {
        columns.append(column)
        setVisibleColumns()
        return column
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
    
    func getNextDefaultColumnName() -> String {
        return "Column\(columns.count + 1)"
    }

    func findFocusedColumn() -> ColumnModel? {
        var model: ColumnModel?
        for column in columns {
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
        for _ in 1 ... 150 {
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
        case visibleColumns
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sheetName = try container.decode(String.self, forKey: .sheetName)
        columns = try container.decode([ColumnModel].self, forKey: .columns)
        visibleColumns = try container.decode([ColumnModel].self, forKey: .visibleColumns)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(sheetName, forKey: .sheetName)
        try container.encode(columns, forKey: .columns)
        try container.encode(visibleColumns, forKey: .visibleColumns)
    }
}
