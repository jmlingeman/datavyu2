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
    
    var body: some View {
        ScrollView {
            HStack {
                ForEach(self.sheetDataModel.columns) { column in
                    Column(columnDataModel: column)
                        .focused($focusedColumn)
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
