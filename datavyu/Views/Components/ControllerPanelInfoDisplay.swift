//
//  ControllerPanelInfoDisplay.swift
//  Datavyu2
//
//  Created by Jesse Lingeman on 7/31/24.
//

import Foundation
import SwiftUI

struct ControllerPanelInfoDisplay: View {
    var labelText: String
    @Binding var data: String
    var disabled: Bool = false
    var onChangeFunction: ((any Equatable, any Equatable) -> Void)?
    var formatter: TimestampFormatter?

    var body: some View {
        ZStack {
//            Rectangle().background(Color.accentColor).frame(width: 150, height: 60)
            LabeledContent {
                if formatter == nil {
                    TextField(text: $data) {
                        Text(labelText)
                    }.frame(width: 100)
                } else {
                    TextField(labelText, value: $data,
                              formatter: formatter!,
                              prompt: Text(labelText))
                        .frame(width: 100)
                }

            } label: {
                Text(labelText)
            }
        }.frame(width: 150, height: 60)
//            .onChange(of: data, perform: { newValue in
//                onChangeFunction(newValue)
//            })
    }
}

struct ControllerPanelInfoDisplayTimestamp: View {
    var labelText: String
    @Binding var data: Int
    var disabled: Bool = false
    var onChangeFunction: ((any Equatable, any Equatable) -> Void)?
    var formatter: TimestampFormatter = .init()

    var body: some View {
        ZStack {
            LabeledContent {
                TextField(labelText, value: $data,
                          formatter: formatter,
                          prompt: Text(labelText))
                    .frame(width: 100)
            } label: {
                Text(labelText)
            }
        }.frame(width: 150, height: 60)
//            .onChange(of: data, onChangeFunction ?? { _, _ in })
    }
}
