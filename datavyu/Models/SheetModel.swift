//
//  File.swift
//  sheettest
//
//  Created by Jesse Lingeman on 6/2/23.
//

import Foundation
import AppKit

final class SheetModel: ObservableObject, Identifiable, Equatable, Codable {

    
    @Published var sheetName: String
    @Published var columns: [ColumnModel]
    @Published var updates: Int = 0
    @Published var updated: Bool = false
    
    let config = Config()
    
    
    init(sheetName: String) {
        self.sheetName = sheetName
        columns = [ColumnModel]()
        setup()
    }
    
    static func == (lhs: SheetModel, rhs: SheetModel) -> Bool {
        return lhs.columns == rhs.columns
    }
    
    func addColumn(columnName: String) {
        columns.append(ColumnModel(sheetModel: self, columnName: columnName))
    }

    func addColumn(column: ColumnModel) {
        columns.append(column)
    }
    
    func setup() {
        let column = ColumnModel(sheetModel: self, columnName: "Test1")
        let column2 = ColumnModel(sheetModel: self, columnName: "Test2")
        addColumn(column: column)
        addColumn(column: column2)
        for _ in 1...150 {
            let _ = column.addCell()
        }
        let _ = column2.addCell()
    }
    
    func setColumn(column: ColumnModel) {
        DispatchQueue.main.async {
            let colIdx = self.columns.firstIndex(where: { c in
                c.columnName == column.columnName
            })
            
            if colIdx == nil {
                self.addColumn(column: column)
            } else {
                self.columns[colIdx!] = column
                self.updates += 1
            }
        }

    }
    
    enum CodingKeys: CodingKey {
        case sheetName
        case columns
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sheetName = try container.decode(String.self, forKey: .sheetName)
        columns = try container.decode(Array<ColumnModel>.self, forKey: .columns)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(sheetName, forKey: .sheetName)
        try container.encode(columns, forKey: .columns)
    }
}
