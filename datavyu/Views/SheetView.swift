//
//  SheetView.swift
//  sheettest
//
//  Created by Jesse Lingeman on 6/2/23.
//

import Foundation
import SwiftUI
import TimecodeKit
import WrappingHStack

struct Sheet: View {
    @ObservedObject var sheetDataModel: SheetModel
    @FocusState private var focusedColumn: Bool
    @FocusState var columnInFocus: ColumnModel?
    @State private var offset : CGPoint = .zero
    

    var body: some View {
        GeometryReader { gr in
            ScrollViewReader { proxy in
                // TODO: Have this proxy scroll us to new columns and cells
                
                Text("").id("top") // Anchor for 2d scrollview
                ScrollView([.horizontal, .vertical], showsIndicators: true) {
                    LazyHStack(alignment: .top) {
                        ForEach(sheetDataModel.columns) { column in
                            Column(columnDataModel: column)
                                .focused($columnInFocus, equals: column)
                        }
                    }
                    .frame(minHeight: gr.size.height)
                }.onAppear {
                    proxy.scrollTo("top")
                }
            }
        }
    
    }
}

struct SheetWeakTemporal: View {
    @ObservedObject var sheetDataModel: SheetModel
    @FocusState private var focusedColumn: Bool
    @FocusState var columnInFocus: ColumnModel?
    @State private var offset : CGPoint = .zero
    
    
    var body: some View {
        GeometryReader { gr in
            ScrollViewReader { proxy in
                // TODO: Have this proxy scroll us to new columns and cells
                
                Text("").id("top") // Anchor for 2d scrollview
                ScrollView([.horizontal, .vertical], showsIndicators: true) {
                    LazyHStack(alignment: .top) {
                        ForEach(sheetDataModel.columns) { column in
                            Column(columnDataModel: column)
                                .focused($columnInFocus, equals: column)
                        }
                    }
                    .frame(minHeight: gr.size.height)
                }.onAppear {
                    proxy.scrollTo("top")
                }
            }
        }
        
    }
}

func layoutWeakTemporal(sheetDataModel: SheetModel) {
    let positions: [CellModel, CGPoint] = [:]
    let cells: [CellModel] = []
    let s = Sheet()
    let config = Config()
    
    ForEach(sheetDataModel.columns) { column in
        ForEach(column.cells) { cell in
            cells.append(cell)
        }
    }
    let minOnset = cells.min(by: { (a, b) -> Bool in
        return a.onset < b.onset
    })
    let maxOnset = cells.max(by: { (a, b) -> Bool in
        return a.onset < b.onset
    })
    let maxOffset = cells.max(by: { (a, b) -> Bool in
        return a.offset < b.offset
    })
    
    /*
     Go through each cell, mark its relative position based on onset
     and its relative position for offset. We'll use these relative
     numbers to figure out the actual positioning during layout.
     */
    
    
}

struct Sheet_Previews: PreviewProvider {
    static var previews: some View {
        let sheetDataModel = SheetModel(sheetName: "TestSheet")
        Sheet(sheetDataModel: sheetDataModel)
    }
}
