//
//  CodeEditorView.swift
//  datavyu
//
//  Created by Jesse Lingeman on 6/4/23.
//

import SwiftUI
import WrappingHStack

class SelectedArgument: ObservableObject, Equatable {
    static func == (lhs: SelectedArgument, rhs: SelectedArgument) -> Bool {
        lhs.column == rhs.column && lhs.argument == rhs.argument
    }

    @Published var column: ColumnModel?
    @Published var argumentIdx: Int? = 0
    @Published var argument: Argument?

    func updateIdx() {
        argumentIdx = column?.getArgumentIndex(argument)
    }
}

struct CodeEditorView: View {
    @ObservedObject var sheetModel: SheetModel
    @Environment(\.dismiss) var dismiss
    @StateObject var selectedArgument: SelectedArgument = .init()
    @State var showingError: Bool = false
    @State var errorMessage: DatavyuLocalizedError?

    var body: some View {
        ScrollView(.vertical) {
            Text("Code Editor").font(.system(size: 30)).frame(alignment: .topLeading).padding()
            HStack {
                Button {
                    if selectedArgument.argumentIdx! - 1 < 0 {
                        return
                    }
                    selectedArgument.column?.moveArgumentLeft(argumentIdx: selectedArgument.column!.getArgumentIndex(selectedArgument.argument) ?? 0)
                    print("Old idx \(selectedArgument.argumentIdx)")
                    selectedArgument.updateIdx()
                    print("New idx \(selectedArgument.argumentIdx)")
//                    selectedArgument.column?.reorderCount -= 1
                } label: {
                    Text("Move Argument Left")
                }
                Button {
                    if selectedArgument.argumentIdx! + 1 > selectedArgument.column!.arguments.count - 1 {
                        return
                    }
                    selectedArgument.column?.moveArgumentRight(argumentIdx: selectedArgument.column!.getArgumentIndex(selectedArgument.argument) ?? 0)
                    print("Old idx \(selectedArgument.argumentIdx)")
                    selectedArgument.updateIdx()
                    print("New idx \(selectedArgument.argumentIdx)")
//                    selectedArgument.column?.reorderCount += 1
                } label: {
                    Text("Move Argument Right")
                }
            }
            .alert(isPresented: $showingError, error: errorMessage) { _ in
            } message: { error in
                if let message = error.errorMessage {
                    Text(message)
                }
            }
            ForEach(sheetModel.columns, id: \.self) { column in
                HStack {
                    CodeEditorRow(column: column, selectedArgument: selectedArgument).padding()
                }
            }
            Button("Add Column") {
                do {
                    try sheetModel.addColumn(columnName: sheetModel.getNextDefaultColumnName())
                } catch DatavyuError.columnNameExists {
                    errorMessage = DatavyuLocalizedError.columnNameExists
                    showingError = true
                } catch {}
            }
            Button("Close") {
                dismiss()
                sheetModel.updateArgumentNames()
                sheetModel.updateSheet() // Force sheet update when we close
            }.padding()
        }
    }
}
