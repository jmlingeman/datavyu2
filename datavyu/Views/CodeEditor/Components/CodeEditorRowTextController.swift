//
//  CodeEditorRowTextController.swift
//  datavyu
//
//  Created by Jesse Lingeman on 5/26/24.
//

import Foundation

class CodeEditorRowTextController {
    var column: ColumnModel

    static let argumentSeperator: String = ","
    static let argumentStartCharacter: Character = "("
    static let argumentEndCharacter: Character = ")"
    var selectionExtent = SelectionExtent()

    var currentExtents = [Int: SelectionExtent]()
    var columnNameExtent = SelectionExtent()

    init(column: ColumnModel) {
        self.column = column
    }

    func getExtentOfArgument(idx: Int) -> SelectionExtent {
        parseUpdates(newValue: rowString())
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
        let columnName = String(newValue.split(separator: "(").first!)
        if columnName.count > 0 {
            column.columnName = columnName
        }

        columnNameExtent.start = 0
        columnNameExtent.end = columnName.count

        let argValues = String(newValue[newValue.index(after: newValue.firstIndex(of: CodeEditorRowTextController.argumentStartCharacter)!) ..< newValue.lastIndex(of: CodeEditorRowTextController.argumentEndCharacter)!])

        var args = argValues.split(by: CodeEditorRowTextController.argumentSeperator, behavior: .isolated)
        // We need to add back in things that may have been stripped due to being empty
        // so if the list starts with a ",", ends with ",", or has 2 "," in a row, we add in a blank

        if args.first == CodeEditorRowTextController.argumentSeperator {
            args.insert("", at: 0)
        }
        if args.last == CodeEditorRowTextController.argumentSeperator {
            args.append("")
        }
        for i in Range(uncheckedBounds: (0, args.count - 1)) {
            let a1 = args[i]
            let a2 = args[i + 1]
            if a1 == CodeEditorRowTextController.argumentSeperator, a2 == CodeEditorRowTextController.argumentSeperator {
                args.insert("", at: i + 1)
            }
        }
        var startIdx = columnNameExtent.end + 2
        var endIdx = 0
        var i = 0
        for arg in args {
            if arg != CodeEditorRowTextController.argumentSeperator {
                print(arg)
                print(arg.contains("^<.*>$"))
                let name = arg.replacingOccurrences(of: "<", with: "").replacingOccurrences(of: ">", with: "")
                if column.arguments[i].name != name {
                    column.arguments[i].setName(name: name)
//                    setValue(value: arg)
                }

                endIdx = startIdx + column.arguments[i].name.count
                currentExtents[i] = SelectionExtent(start: startIdx, end: endIdx)
                startIdx = endIdx // Add 1 to skip the seperator
                i += 1
            }
        }
        return rowString()
    }

    func rowString() -> String {
        var strcmp = [String]()
        for arg in column.arguments {
            strcmp.append(arg.getDisplayString())
        }
        return column.columnName + "(" + strcmp.joined(separator: CellTextController.argumentSeperator) + ")"
    }
}
