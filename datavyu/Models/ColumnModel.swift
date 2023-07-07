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
    @Published var arguments: [Argument] = [Argument(name: "test1"), Argument(name: "test2")]
    @Published var hidden: Bool = false

    static func == (lhs: ColumnModel, rhs: ColumnModel) -> Bool {
        if lhs.columnName == rhs.columnName {
            return true
        }
        return false
    }
        
    func addArgument() {
        let newArg = Argument(name: "code\(arguments.count)")
        arguments.append(newArg)
        for cell in cells {
            cell.arguments.append(newArg)
        }
    }
    
    func addArgument(argument: Argument) {
        arguments.append(argument)
        for cell in cells {
            cell.arguments.append(argument)
        }
    }
    

    func hash(into hasher: inout Hasher) {
        hasher.combine(columnName)
    }

    init(columnName: String) {
        self.columnName = columnName
        cells = [CellModel]()
    }
    
    init(columnName: String, arguments: [Argument]) {
        self.columnName = columnName
        self.arguments = arguments
        cells = [CellModel]()
    }
    
    init(columnName: String, arguments: [Argument], hidden: Bool) {
        self.columnName = columnName
        self.arguments = arguments
        self.hidden = hidden
        cells = [CellModel]()
    }

    func addCell(cell: CellModel) -> CellModel {
        cell.ordinal = cells.count + 1
        cells.append(cell)
        return cell
    }
    
    func addCell() -> CellModel {
        let cell = CellModel(column: self)
        cells.append(cell)
        return cell
    }
}
