//
//  FocusController.swift
//  Datavyu2
//
//  Created by Jesse Lingeman on 9/24/24.
//

import Foundation
import SwiftUI

class FocusController: NSObject, ObservableObject {
    @Published var focusedSheetModel: SheetModel?
    @Published var focusedColumn: ColumnModel?
    @Published var focusedCell: CellModel?
    @Published var focusedArgument: Argument?

    func setFocusedSheetModel(sheetModel: SheetModel) {
        if focusedSheetModel != sheetModel {
            focusedSheetModel = sheetModel
            focusedColumn = nil
            focusedCell = nil
            focusedArgument = nil
        }
    }

    func setFocusedColumn(columnModel: ColumnModel) {
        setFocusedSheetModel(sheetModel: columnModel.sheetModel!)
        if focusedColumn != columnModel {
            focusedColumn?.isSelected = false

            focusedColumn = columnModel
            focusedCell = nil
            focusedArgument = nil

            focusedColumn?.isSelected = true
        }
    }

    func setFocusedCell(cell: CellModel?) {
        if cell == nil {
            focusedCell = nil
        } else {
            setFocusedColumn(columnModel: cell!.column!)
            if focusedCell != cell {
                focusedCell = cell
                focusedArgument = cell!.arguments.first

                focusedCell?.isSelected = true
            }
        }
    }

//    func setSelectedCell(selectedCell: CellModel?) {
//        if self.selectedCell != selectedCell {
//            DispatchQueue.main.async {
//                self.selectedCell = selectedCell
//                selectedCell?.isSelected = true
//                if selectedCell != nil {
//                    self.setSelectedColumn(model: selectedCell!.column!, suppress_update: true)
//                }
//            }
//        }
//    }

//    func setSelectedColumn(model: ColumnModel, suppress_update: Bool = false) {
//        Logger.info("Setting column \(model.columnName) to selected")
//        DispatchQueue.main.async {
//            for column in self.columns {
//                if model == column {
//                    if column.sheetModel?.focusController.focusedColumn != column {
//                        column.sheetModel?.setSelectedCell(selectedCell: nil)
//                    }
//                    column.isSelected = true
//
//                } else {
//                    column.isSelected = false
//                }
//            }
//            if !suppress_update {
//                self.updateSheet()
//            }
//        }
//    }

//    func setFocusArgument(argument: Argument) {
//
//    }
}
