//
//  ArgumentModel.swift
//  sheettest
//
//  Created by Jesse Lingeman on 6/2/23.
//

import Foundation
import Vapor

final class Argument: ObservableObject, Identifiable, Equatable, Hashable, Codable, Content {
    @Published var name: String
    @Published var value: String
    @Published var column: ColumnModel

    @Published var isLastArgument: Bool = false

    var undoManager: UndoManager?
    var id: UUID = .init()

    static func == (lhs: Argument, rhs: Argument) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    init() {
        name = ""
        value = ""
        column = ColumnModel()
        undoManager = column.sheetModel.undoManager
    }

    init(name: String, column: ColumnModel) {
        self.name = name
        value = ""
        self.column = column
        undoManager = column.sheetModel.undoManager
    }

    init(name: String, value: String, column: ColumnModel) {
        self.name = name
        self.value = value
        self.column = column
        undoManager = column.sheetModel.undoManager
    }

    func copy(columnModelCopy: ColumnModel) -> Argument {
        let newArgument = Argument(name: name, value: value, column: columnModelCopy)
        return newArgument
    }
    
    func getPlaceholder() -> String {
        return "<\(self.name)>"
    }
    
    func getDisplayString() -> String {
        if self.value.count > 0 {
            return self.value
        } else {
            return getPlaceholder()
        }
    }

    func setUndoManager(undoManager: UndoManager) {
        self.undoManager = undoManager
    }

    func setValue(value: String) {
        let oldValue = self.value
        let valueWithoutSep = value.replacingOccurrences(of: CellTextController.argumentSeperator, with: "")
        self.value = value
        undoManager?.registerUndo(withTarget: self, handler: { _ in
            self.value = oldValue
            self.update()
        })
        update()
    }

    func setName(name: String) {
        let oldName = self.name
        self.name = name
        undoManager?.registerUndo(withTarget: self, handler: { _ in
            self.name = name
            self.update()
        })
        update()
    }

    func update() {
        column.sheetModel.updates += 1
    }

    func blankCopy() -> Argument {
        Argument(name: name, column: column)
    }

    enum CodingKeys: CodingKey {
        case name
        case value
        case column
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        value = try container.decode(String.self, forKey: .value)
        column = try container.decode(ColumnModel.self, forKey: .column)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(value, forKey: .value)
        try container.encode(column, forKey: .column)
    }
}
