//
//  CellModel.swift
//  sheettest
//
//  Created by Jesse Lingeman on 6/2/23.
//

import Foundation
import Vapor

final class CellModel: ObservableObject, Identifiable, Equatable, Hashable, Codable, Content, Comparable {
    @Published var column: ColumnModel
    @Published var onset: Int = 0
    @Published var offset: Int = 0
    @Published var ordinal: Int = 0
    @Published var comment: String = ""
    @Published var arguments: [Argument] = []
    @Published var onsetPosition: Double = 0
    @Published var offsetPosition: Double = 0

    var undoManager: UndoManager?

    init() {
        column = ColumnModel(sheetModel: SheetModel(sheetName: "dummy"), columnName: "dummy")
        undoManager = column.sheetModel.undoManager
        syncArguments()
    }

    init(column: ColumnModel) {
        self.column = column
        undoManager = column.sheetModel.undoManager
        syncArguments()
    }

    static func == (lhs: CellModel, rhs: CellModel) -> Bool {
        lhs.onset == rhs.onset && lhs.offset == rhs.offset && lhs.arguments == rhs.arguments && lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(onset)
        hasher.combine(offset)
        hasher.combine(arguments)
        hasher.combine(id)
    }

    func updateArgumentNames() {
        for (idx, argument) in arguments.enumerated() {
            if argument.name != column.arguments[idx].name {
                argument.setName(name: column.arguments[idx].name)
            }
        }
    }

    func setUndoManager(undoManager: UndoManager) {
        self.undoManager = undoManager

        for arg in arguments {
            arg.setUndoManager(undoManager: undoManager)
        }
    }

    func copy(columnModelCopy: ColumnModel) -> CellModel {
        let newCellModel = CellModel(column: columnModelCopy)
        newCellModel.onset = onset
        newCellModel.offset = offset
        newCellModel.arguments = arguments.map { a in
            a.copy(columnModelCopy: columnModelCopy)
        }
        newCellModel.ordinal = ordinal
        return newCellModel
    }

    static func < (lhs: CellModel, rhs: CellModel) -> Bool {
        if lhs.onset == rhs.onset {
            return lhs.offset < rhs.offset
        } else {
            return lhs.onset < rhs.onset
        }
    }

    func syncArguments() {
        let args = column.arguments
        for arg in args {
            var found = false
            for x in arguments {
                if arg.name == x.name {
                    found = true
                }
            }
            if !found {
                arguments.append(Argument(name: arg.name, column: arg.column))
            }
        }
        arguments.last?.isLastArgument = true
    }

    func setOnset(onset: Int) {
        print(#function)
        if onset != self.onset {
            DispatchQueue.main.async {
                let oldOnset = self.onset
                self.onset = onset
                self.undoManager?.beginUndoGrouping()
                self.undoManager?.registerUndo(withTarget: self, handler: { _ in
                    self.onset = oldOnset
                    self.updateSheet()
                })
                self.undoManager?.endUndoGrouping()
                self.updateSheet()
            }
        }
    }

    func updateSheet() {
        column.sheetModel.updates += 1
    }

    func setOnset(onset: Double) {
        print(#function)
        setOnset(onset: Int(onset * 1000))
    }

    func setOnset(onset: String) {
        print(#function)
        setOnset(onset: timestringToTimestamp(timestring: onset))
    }

    func setOffset(offset: String) {
        print(#function)
        setOffset(offset: timestringToTimestamp(timestring: offset))
    }

    func setOffset(offset: Int) {
        print(#function)
        if offset != self.offset {
            DispatchQueue.main.async {
                let oldOffset = self.offset
                self.offset = offset
                self.undoManager?.beginUndoGrouping()
                self.undoManager?.registerUndo(withTarget: self, handler: { _ in
                    self.offset = oldOffset
                    self.updateSheet()
                })
                self.undoManager?.endUndoGrouping()
                self.updateSheet()
            }
        }
    }

    func setOffset(offset: Double) {
        setOffset(offset: Int(offset * 1000))
    }

    func setArgumentValue(index: Int, value: String) {
        arguments[index].setValue(value: value)
    }

    func getArgumentIndex(_ argument: Argument?) -> IndexPath {
        if argument != nil {
            return IndexPath(item: arguments.firstIndex(of: argument!) ?? 0, section: 0)
        } else {
            return IndexPath(item: 0, section: 0)
        }
    }

    func getNextArgumentIndex(_ argument: Argument) -> IndexPath {
        let idx = (arguments.firstIndex(of: argument) ?? 0) + 1
        return IndexPath(item: idx, section: 0)
    }

//    static func == (lhs: CellModel, rhs: CellModel) -> Bool {
//        if lhs.id == rhs.id {
//            return true
//        }
//        return false
//    }

    enum CodingKeys: CodingKey {
        case onset
        case offset
        case comment
        case arguments
        case column
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        onset = try container.decode(Int.self, forKey: .onset)
        offset = try container.decode(Int.self, forKey: .offset)
        comment = try container.decode(String.self, forKey: .comment)
        arguments = try container.decode([Argument].self, forKey: .arguments)
        column = try container.decode(ColumnModel.self, forKey: .column)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(onset, forKey: .onset)
        try container.encode(offset, forKey: .offset)
        try container.encode(comment, forKey: .comment)
        try container.encode(arguments, forKey: .arguments)
        try container.encode(column, forKey: .column)
    }
}
