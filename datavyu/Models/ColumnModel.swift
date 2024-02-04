//
//  ColumnModel.swift
//  sheettest
//
//  Created by Jesse Lingeman on 6/2/23.
//

import Foundation
import Vapor

final class ColumnModel: ObservableObject, Identifiable, Equatable, Hashable, Codable, Content {
    @Published var sheetModel: SheetModel
    @Published var columnName: String
    @Published var cells: [CellModel]
    @Published var arguments: [Argument]
    @Published var hidden: Bool = false
    
    init() {
        self.sheetModel = SheetModel(sheetName: "dummy")
        self.columnName = "dummy"
        self.cells = []
        self.arguments = []
        addArgument()
    }
    
    static func == (lhs: ColumnModel, rhs: ColumnModel) -> Bool {
        return lhs.cells == rhs.cells
    }
    
    func setHidden(val: Bool) {
        self.hidden = val
    }
        
    func addArgument() {
        let newArg = Argument(name: "code\(arguments.count)", column: self)
        addArgument(argument: newArg)
    }
    
    func getSortedCells() -> [CellModel] {
        return cells.sorted()
    }
    
    func removeArgument() {
        let _ = arguments.popLast()
        for cell in cells {
            let _ = cell.arguments.popLast()
        }
        self.sheetModel.updates += 1
    }
    
    func addArgument(argument: Argument) {
        arguments.append(argument)
        for cell in cells {
            cell.arguments.append(argument)
        }
        self.sheetModel.updates += 1
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(columnName)
    }

    init(sheetModel: SheetModel, columnName: String) {
        self.sheetModel = sheetModel
        self.columnName = columnName
        cells = []
        self.arguments = []
        addArgument()
    }
    
    init(sheetModel: SheetModel, columnName: String, arguments: [Argument]) {
        self.sheetModel = sheetModel
        self.columnName = columnName
        self.arguments = arguments
        cells = []
    }
    
    init(sheetModel: SheetModel, columnName: String, arguments: [Argument], hidden: Bool) {
        self.sheetModel = sheetModel
        self.columnName = columnName
        self.arguments = arguments
        self.hidden = hidden
        cells = []
    }

    func addCell(cell: CellModel) -> CellModel {
        cell.ordinal = cells.count + 1
        cells.append(cell)
        return cell
    }
    
    func addCell() -> CellModel {
        let cell = CellModel(column: self)
        cell.ordinal = cells.count + 1
        cells.append(cell)
        return cell
    }
    
    enum CodingKeys: CodingKey {
        case columnName
        case cells
        case arguments
        case sheetModel
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        columnName = try container.decode(String.self, forKey: .columnName)
        cells = try container.decode(Array<CellModel>.self, forKey: .cells)
        arguments = try container.decode(Array<Argument>.self, forKey: .arguments)
        sheetModel = try container.decode(SheetModel.self, forKey: .sheetModel)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(columnName, forKey: .columnName)
        try container.encode(cells, forKey: .cells)
        try container.encode(arguments, forKey: .arguments)
        try container.encode(sheetModel, forKey: .sheetModel)
    }
}
