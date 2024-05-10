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
    @Published var isSelected: Bool = false
    @Published var isFinished: Bool = false
    
    var undoManager: UndoManager?
    
    init() {
        self.sheetModel = SheetModel(sheetName: "dummy")
        self.columnName = "dummy"
        self.cells = []
        self.arguments = []
        addArgument()
        
        self.undoManager = sheetModel.undoManager
    }
    
    init(sheetModel: SheetModel, columnName: String) {
        self.sheetModel = sheetModel
        self.columnName = columnName
        self.cells = []
        self.arguments = []
        addArgument()
        
        self.undoManager = sheetModel.undoManager
    }
    
    init(sheetModel: SheetModel, columnName: String, arguments: [Argument]) {
        self.sheetModel = sheetModel
        self.columnName = columnName
        self.arguments = arguments
        self.cells = []
        
        self.undoManager = sheetModel.undoManager
    }
    
    init(sheetModel: SheetModel, columnName: String, arguments: [String]) {
        self.sheetModel = sheetModel
        self.columnName = columnName
        self.arguments = []
        self.cells = []
        
        for argname in arguments {
            addArgument(argument: Argument(name: argname, column: self))
        }
        
        self.undoManager = sheetModel.undoManager
    }
    
    init(sheetModel: SheetModel, columnName: String, arguments: [Argument], hidden: Bool) {
        self.sheetModel = sheetModel
        self.columnName = columnName
        self.arguments = arguments
        self.hidden = hidden
        self.cells = []
        
        self.undoManager = sheetModel.undoManager
    }
    
    static func == (lhs: ColumnModel, rhs: ColumnModel) -> Bool {
        return lhs.id == rhs.id
    }
    
    func setUndoManager(undoManager: UndoManager) {
        self.undoManager = undoManager
        
        for cell in cells {
            cell.setUndoManager(undoManager: undoManager)
        }
    }
    
    func setHidden(val: Bool) {
        self.hidden = val
    }
        
    func addArgument() {
        let newArg = Argument(name: "code\(arguments.count)", column: self)
        addArgument(argument: newArg)
    }
    
    func addArgument(argument: Argument) {
        self.arguments.last?.isLastArgument = false

        arguments.append(argument)
        for cell in cells {
            cell.arguments.append(argument)
            self.undoManager?.registerUndo(withTarget: self, handler: { _ in
                cell.arguments.removeAll { a in
                    a == argument
                }
                self.update()
            })
        }
        
        self.arguments.last?.isLastArgument = true

        update()
    }
    
    func getSortedCells() -> [CellModel] {
        let sortedCells = cells.sorted()
        for (i, c) in sortedCells.enumerated() {
            c.ordinal = i + 1
        }
        return sortedCells
    }
    
    func copy(sheetModelCopy: SheetModel) -> ColumnModel {
        let newColumnModel = ColumnModel(sheetModel: sheetModelCopy, 
                                         columnName: self.columnName)
        
        newColumnModel.arguments = self.arguments.map({ a in
            a.copy(columnModelCopy: newColumnModel)
        })
        
        newColumnModel.cells = self.cells.map({ c in
            c.copy(columnModelCopy: newColumnModel)
        })
        
        return newColumnModel
    }
    
    func removeArgument() {
        let _ = arguments.popLast()
        for cell in cells {
            let _ = cell.arguments.popLast()
        }
        update()
    }
    
    func update() {
        print("Updating")
        self.sheetModel.updates += 1
    }
    
    

    func hash(into hasher: inout Hasher) {
        hasher.combine(columnName)
    }
    
    func toggleFinished() {
        self.isFinished = !self.isFinished
        update()
    }

    func addCell(cell: CellModel, force: Bool = false) -> CellModel? {
        if !isFinished || force {
            cell.ordinal = cells.count + 1
            cells.append(cell)
            
            self.undoManager?.registerUndo(withTarget: self, handler: { _ in
                self.cells.removeAll { c in
                    c == cell
                }
                self.update()
            })
            
            return cell
        }
        return nil
    }
    
    func addCell(force: Bool = false) -> CellModel? {
        let cell = CellModel(column: self)
        return addCell(cell: cell, force: force)
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
