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

struct Sheet_Previews: PreviewProvider {
    static var previews: some View {
        let sheetDataModel = SheetModel(sheetName: "TestSheet")
        Sheet(sheetDataModel: sheetDataModel)
    }
}

func placeSubviews(
    in bounds: CGRect,
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache: inout Void
) {
    guard !subviews.isEmpty else { return }
    
    
    let maxSize = maxSize(subviews: subviews)
    let spacing = spacing(subviews: subviews)
    
    
    let placementProposal = ProposedViewSize(width: maxSize.width, height: maxSize.height)
    var nextX = bounds.minX + maxSize.width / 2
    
    
    for index in subviews.indices {
        subviews[index].place(
            at: CGPoint(x: nextX, y: bounds.midY),
            anchor: .center,
            proposal: placementProposal)
        nextX += maxSize.width + spacing[index]
    }
}

