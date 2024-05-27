//
//  CellTextController.swift
//  datavyu
//
//  Created by Jesse Lingeman on 5/26/24.
//

import Foundation

struct SelectionExtent {
    var start: Int = 0
    var end: Int = 0
}

class CellTextController {
    var cell: CellModel
    
    static let argumentSeperator: String = ","
    var selectionExtent = SelectionExtent()
    
    var currentExtents = [Int: SelectionExtent]()
    
    init(cell: CellModel) {
        self.cell = cell
    }
    
    func getExtentOfArgument(idx: Int) -> SelectionExtent {
        parseUpdates(newValue: argumentString())
        return currentExtents[idx]!
    }
    
    func getExtentForIdx(idx: Int) -> SelectionExtent {
        for extent in currentExtents.values {
            if idx >= extent.start && idx <= extent.end {
                return extent
            }
        }
        return SelectionExtent()
    }
    
    func getArgIdxForIdx(idx: Int) -> Int {
        for i in currentExtents.keys {
            let extent = currentExtents[i]!
            if idx >= extent.start && idx <= extent.end {
                return i
            }
        }
        return 0
    }
    
    func parseUpdates(newValue: String) -> String {
        let args = newValue.split(by: CellTextController.argumentSeperator, behavior: .removed)
        var startIdx = 0
        var endIdx = 0
        for (i, arg) in args.enumerated() {
            if cell.arguments.count > i {
                if cell.arguments[i].value != arg {
                    cell.arguments[i].value = arg
                }
                
                endIdx = startIdx + cell.arguments[i].getDisplayString().count
                currentExtents[i] = SelectionExtent(start: startIdx, end: endIdx)
                startIdx = endIdx + 1 // Add 1 to skip the seperator
            }
        }
        return argumentString()
    }
    
    func argumentString() -> String {
        var strcmp = [String]()
        for arg in cell.arguments {
            if arg.value.count > 0 {
                strcmp.append(arg.value)
            } else {
                strcmp.append(arg.getPlaceholder())
            }
        }
        return strcmp.joined(separator: CellTextController.argumentSeperator)
    }
}
