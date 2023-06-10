//
//  Cell.swift
//  sheettest
//
//  Created by Jesse Lingeman on 6/2/23.
//

import SwiftUI
import TimecodeKit
import WrappingHStack

struct Cell: View {
    @ObservedObject var cellDataModel: CellModel
    var isEditing: FocusState<Bool>.Binding

    let tcFormatter =
        Timecode.TextFormatter(frameRate: ._29_97,
                               limit: ._24hours,
                               stringFormat: [.showSubFrames],
                               subFramesBase: ._80SubFrames,
                               showsValidation: true, // enable invalid component highlighting
                               validationAttributes: nil) // if nil, defaults to red foreground color

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
                }.padding().border(Color.black, width: 1)
            }
        }.textFieldStyle(.plain)
            .border(Color.black, width: 4)
            .focused(isEditing)
            .offset(y: cellDataModel.onsetPosition)
            .frame(height: cellDataModel.offsetPosition)
            .padding()

    }
}
