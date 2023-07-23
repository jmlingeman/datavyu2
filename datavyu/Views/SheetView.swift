//
//  SheetView.swift
//  sheettest
//
//  Created by Jesse Lingeman on 6/2/23.
//

import Foundation
import SwiftUI
import WrappingHStack

struct Sheet: View {
    @ObservedObject var sheetDataModel: SheetModel
    @FocusState var columnInFocus: ColumnModel?
    @FocusState var cellInFocus: CellModel?
    @State private var offset: CGPoint = .zero
    @FocusState private var isFocused: Bool
    @Binding var temporalLayout: Bool
//    @ObservedObject var columnWidths:
    
    let config = Config()

    var body: some View {
        let sheetLayout = temporalLayout ? AnyLayout(WeakTemporalLayout(sheetModel: $sheetDataModel)) : AnyLayout(OrdinalLayout(sheetModel: $sheetDataModel))
        
        VStack {
            ScrollViewReader { proxy in
                // TODO: Have this proxy scroll us to new columns and cells
                
                Text("").id("top") // Anchor for 2d scrollview
                GeometryReader { sheetGr in
                    ScrollView([.horizontal, .vertical], showsIndicators: true) {
                        sheetLayout {
                            ForEach(Array($sheetDataModel.columns.enumerated()), id: \.offset) { idx, $column in
                                EditableLabel($column.columnName)
                                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                                    .focused($columnInFocus, equals: column)
                                    .background(columnInFocus == column ? Color.blue : Color.black)
                                    .frame(width: Double(config.defaultCellWidth), height: config.headerSize)
                                    .setColumnIdx(idx)
                                    .setObjectType("title")
                                ForEach(Array(zip(column.cells.indices, column.cells)), id: \.0) { cellIdx, cell in
                                    Cell(parentColumn: column, cellDataModel: cell, columnInFocus: $columnInFocus, cellInFocus: $cellInFocus)
                                        .setColumnIdx(idx).setObjectType("cell").setCellIdx("\(column.columnName)-\(cellIdx)")
                                }
                            }
                        }
                        .frame(minHeight: sheetGr.size.height)
                    }.onAppear {
                        proxy.scrollTo("top")
                    }
                }
            }
        }
    }
}

struct Sheet_Previews: PreviewProvider {
    static var previews: some View {
        let sheetDataModel = SheetModel(sheetName: "TestSheet")
        @State var temporalLayout = false
        Sheet(sheetDataModel: sheetDataModel, temporalLayout: $temporalLayout)
    }
}
