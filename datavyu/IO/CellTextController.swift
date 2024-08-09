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
            if idx >= extent.start, idx <= extent.end {
                return extent
            }
        }
        return SelectionExtent()
    }

    func getArgIdxForIdx(idx: Int) -> Int {
        for i in currentExtents.keys {
            let extent = currentExtents[i]!
            if idx >= extent.start, idx <= extent.end {
                return i
            }
        }
        return 0
    }

    func parseUpdates(newValue: String) -> String {
        var args = newValue.split(by: CellTextController.argumentSeperator, behavior: .isolated)
        // We need to add back in things that may have been stripped due to being empty
        // so if the list starts with a ",", ends with ",", or has 2 "," in a row, we add in a blank
        if args.first == CellTextController.argumentSeperator {
            args.insert("", at: 0)
        }
        if args.last == CellTextController.argumentSeperator {
            args.append("")
        }
        for i in Range(uncheckedBounds: (0, args.count - 1)) {
            let a1 = args[i]
            let a2 = args[i + 1]
            if a1 == CellTextController.argumentSeperator, a2 == CellTextController.argumentSeperator {
                args.insert("", at: i + 1)
            }
        }
        var startIdx = 0
        var endIdx = 0
        var i = 0
        for arg in args {
            if arg != CellTextController.argumentSeperator {
                Logger.info(arg.contains("^<.*>$"))
                if cell.arguments[i].value != arg || !(arg.starts(with: "<") && arg.last == ">") {
                    cell.arguments[i].setValue(value: arg)
                }

                endIdx = startIdx + cell.arguments[i].getDisplayString().count
                currentExtents[i] = SelectionExtent(start: startIdx, end: endIdx)
                startIdx = endIdx + 1 // Add 1 to skip the seperator
                i += 1
            }
        }
        return argumentString()
    }

    func argumentString() -> String {
        var strcmp = [String]()
        for arg in cell.arguments {
            strcmp.append(arg.getDisplayString())
        }
        return strcmp.joined(separator: CellTextController.argumentSeperator)
    }
}
