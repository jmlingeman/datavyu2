//
//  Cell.swift
//  sheettest
//
//  Created by Jesse Lingeman on 6/2/23.
//

import SwiftUI
import WrappingHStack

struct Cell: View {
    @ObservedObject var cellDataModel: CellModel
    var isEditing: FocusState<Bool>.Binding
    let tcFormatter = MillisTimeFormatter()
    var columnInFocus: FocusState<ColumnModel?>.Binding
    let config = Config()

    var body: some View {
        LazyVStack {
            HStack {
                Text(String(cellDataModel.ordinal))
                Spacer()
                TextField("Onset", value: $cellDataModel.onset, formatter: tcFormatter).frame(minWidth: 100, idealWidth: 100, maxWidth: 100)
                TextField("Offset", value: $cellDataModel.offset, formatter: tcFormatter).frame(minWidth: 100, idealWidth: 100, maxWidth: 100)
            }.padding()
            WrappingHStack(
                $cellDataModel.arguments
            ) { $item in
                VStack {
                    TextField(item.name, text: $item.value, axis: .horizontal)
                        .padding(3)
                        .fixedSize(horizontal: true, vertical: false)
                        .frame(minWidth: 50, idealWidth: 100)
                    Text(item.name)
                }.padding().border(config.cellBorder, width: 1).foregroundColor(config.cellFG)
            }.frame(alignment: .topLeading)
        }.textFieldStyle(.plain)
            .frame(maxHeight: .infinity, alignment: .topLeading)
            .border(config.cellBorder, width: 4)
            .focused(columnInFocus, equals: cellDataModel.column)
            .setOnset($cellDataModel.onset)
            .setOffset($cellDataModel.offset)
            .frame(width: CGFloat(config.defaultCellWidth))
            .fixedSize(horizontal: true, vertical: false)
            .foregroundColor(config.cellFG)
            .background(config.cellBG)
            
    }
}
