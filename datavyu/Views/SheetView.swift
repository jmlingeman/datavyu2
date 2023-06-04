//
//  SheetView.swift
//  sheettest
//
//  Created by Jesse Lingeman on 6/2/23.
//

import Foundation
import SwiftUI
import WrappingHStack
import TimecodeKit

struct Sheet: View {
    @ObservedObject var sheetDataModel: SheetModel
    @FocusState private var focusedColumn: Bool
    @FocusState var columnInFocus: ColumnModel?
        
    var body: some View {
        ScrollView {
            HStack(alignment: .top) {
                ForEach(self.sheetDataModel.columns) { column in
                    Column(columnDataModel: column)
                        .focused($columnInFocus, equals: column)
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
