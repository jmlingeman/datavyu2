//
//  FocusModel.swift
//  datavyu
//
//  Created by Jesse Lingeman on 8/29/23.
//

import Foundation

class ArgumentFocusModel : ObservableObject, Identifiable {
    
    var sheetModel : SheetModel
    @Published var arguments : [Argument] = []
    @Published var argumentMap  = [Argument: Int]()
    
    init(sheetModel: SheetModel) {
        self.sheetModel = sheetModel
        sortArguments(sheetModel: sheetModel)
    }
    
    func update() {
        sortArguments(sheetModel: sheetModel)
    }
    
    func sortArguments(sheetModel: SheetModel) {
        // Use the sheet's column order
        arguments.removeAll(keepingCapacity: true)
        argumentMap.removeAll(keepingCapacity: true)
        
        var idx = 0
        for column in sheetModel.columns {
            for cell in column.getSortedCells() {
                for argument in cell.arguments {
                    arguments.append(argument)
                    argumentMap[argument] = idx
                    idx += 1
                }
            }
        }
    }
}
