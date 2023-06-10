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
    var cellLookup = [ColumnModel : [CellModel]]()
    var cells: [CellModel] = []
    let config = Config()
    
    for column in sheetDataModel.columns {
        for cell in column.cells {
            cells.append(cell)
            cellLookup[column, default: []].append(cell)
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
    
    cells.sort { x, y in
        if(x.onset < y.onset) {
            return true
        } else if (x.onset > y.onset) {
            return false
        } else {
            if(x.offset < y.offset) {
                return true
            } else if (x.offset > y.offset) {
                return false
            } else {
                return true
            }
        }
    }
    
    /*
     Go through each cell, mark its relative position based on onset
     and its relative position for offset. We'll use these relative
     numbers to figure out the actual positioning during layout.
     */
    
    // First cell starts at position 0
    
    var currentPosition = 0
    var prevOnsetPosition = 0
    var prevOffsetPosition = 0
    
    
    for cell in cells {
        cell.onsetPosition = currentPosition
        cell.offsetPosition = currentPosition + 1
        currentPosition += 1
    }
    
    /*
     Another possibility is to go through each cell and mark
     its dependent cells
     */
    
    
}

struct Sheet_Previews: PreviewProvider {
    static var previews: some View {
        let sheetDataModel = SheetModel(sheetName: "TestSheet")
        Sheet(sheetDataModel: sheetDataModel)
    }
}
