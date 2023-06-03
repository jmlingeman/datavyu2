//
//  Cell.swift
//  sheettest
//
//  Created by Jesse Lingeman on 6/2/23.
//

import SwiftUI
import WrappingHStack
import TimecodeKit

struct Cell: View {
    @ObservedObject var cellDataModel: CellModel
    let tcFormatter =
    Timecode.TextFormatter(frameRate: ._29_97,
                           limit: ._24hours,
                           stringFormat: [.showSubFrames],
                           subFramesBase: ._80SubFrames,
                           showsValidation: true,     // enable invalid component highlighting
                           validationAttributes: nil) // if nil, defaults to red foreground color
    
    init(cellDataModel: CellModel) {
        self.cellDataModel = cellDataModel
    }
    
    var body: some View {
        VStack {
            HStack {
                Text(String(cellDataModel.ordinal))
                Spacer()
                TextField("Onset", value: $cellDataModel.onset, formatter: tcFormatter).frame(minWidth: 100, idealWidth: 100, maxWidth: 100)
                TextField("Offset", value: $cellDataModel.offset, formatter: tcFormatter).frame(minWidth: 100, idealWidth: 100, maxWidth: 100)
            }
            WrappingHStack(
                $cellDataModel.arguments
            ) { $item in
                VStack {
                    TextField(item.name, text: $item.value, axis: .horizontal)
                        .padding(3)
                        .fixedSize(horizontal: true, vertical: false)
                        .frame(minWidth: 50, idealWidth: 100)
                    Text(item.name)
                }.padding().border(Color.black, width:1)
            }
        }.textFieldStyle(.plain)
            .padding()
            .border(Color.black, width: 4)
    }
}
