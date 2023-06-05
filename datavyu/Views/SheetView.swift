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
                ScrollView([.horizontal, .vertical], showsIndicators: true) {
                    HStack(alignment: .top) {
                        ForEach(sheetDataModel.columns) { column in
                            Column(columnDataModel: column)
                                .focused($columnInFocus, equals: column)
                        }
                        Spacer()
                    }.id("top")
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
