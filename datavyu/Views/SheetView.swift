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
    @FocusState var argInFocusIdx: Int?
    @State private var offset: CGPoint = .zero
    @FocusState private var isFocused: Bool
    @Binding var temporalLayout: Bool
    
    @State var argumentFocusModel: ArgumentFocusModel
    
    let config = Config()

    var body: some View {
//        let sheetLayout = temporalLayout ? AnyLayout(WeakTemporalLayout(sheetModel: $sheetDataModel)) : AnyLayout(OrdinalLayout(sheetModel: $sheetDataModel))
//        let collectionContent = [1,2,3,4,5,6,7,8]

        
//        VStack {
//            ScrollViewReader { proxy in
                // TODO: Have this proxy scroll us to new columns and cells
                
//                Text("").id("top") // Anchor for 2d scrollview
//                GeometryReader { sheetGr in
//                    ScrollView([.horizontal, .vertical], showsIndicators: true) {
        TemporalLayoutCollection(sheetModel: sheetDataModel, 
                                 itemSize: NSSize.init(width: 100, height: 100)
        )

//                    }.onAppear {
//                        proxy.scrollTo("top")
//                    }
//                }
//            }
//        }
    }
}
