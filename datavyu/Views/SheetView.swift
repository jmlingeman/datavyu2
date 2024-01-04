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
    @EnvironmentObject var sheetModel: SheetModel
    @FocusState var columnInFocus: ColumnModel?
    @FocusState var cellInFocus: CellModel?
    @FocusState var argInFocusIdx: Int?
    @State private var offset: CGPoint = .zero
    @FocusState private var isFocused: Bool
    @Binding var temporalLayout: Bool
    
    @State var argumentFocusModel: ArgumentFocusModel
    
    let config = Config()

    var body: some View {
        GeometryReader { sheetGr in
            VStack {
                TemporalCollectionView().environmentObject(sheetModel)
                
            }
        }
    }
}
