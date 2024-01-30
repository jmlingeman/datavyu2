//
//  Cell.swift
//  sheettest
//
//  Created by Jesse Lingeman on 6/2/23.
//

import SwiftUI
import WrappingHStack
import HierarchyResponder
import SwiftUIIntrospect



struct Cell: View {
//    @ObservedObject var parentColumn: ColumnModel
    @ObservedObject var cellDataModel: CellModel
    @EnvironmentObject var sheetModel: SheetModel
//    var columnInFocus: FocusState<ColumnModel?>.Binding
//    var cellInFocus: FocusState<CellModel?>.Binding
//    @ObservedObject var focusOrderedArguments : ArgumentFocusModel
//    @FocusState var focus: Bool
    
//    @FocusState private var focusedField: Field?
    
    let tcFormatter = MillisTimeFormatter()
    let config = Config()
    
    struct FocusCellEvent: Event {
        let colIdx: Int
        let cellIdx: Int
    }
    
    
        
//    func updateFocus(item: Argument) {
//        if focus.wrappedValue == nil {
//            focus.wrappedValue = focusOrderedArguments.argumentMap[item]
//        } else {
//            focus.wrappedValue = (focus.wrappedValue! + 1) % focusOrderedArguments.arguments.count
//        }
//        focusOrderedArguments.update()
//    }
    @Environment(\.triggerEvent) var nextCellEvent

    var body: some View {
        
        
        LazyVStack {
            HStack {
                Text(String(cellDataModel.ordinal))
                Spacer()
                
                TextField("Onset", value: $cellDataModel.onset, formatter: tcFormatter).frame(minWidth: 100, idealWidth: 100, maxWidth: 100)
                    .onSubmit {
                        sheetModel.updates += 1
                    }
                    
                    
                    .handleEvent(FocusCellEvent.self) { event in
                        print("HANDLING EVENT \(event)")
                        if event.cellIdx == cellDataModel.ordinal {
                            self.introspect(.textField, on: .macOS(.v14)) { textField in
                                textField.becomeFirstResponder()
                            }
                        }
                        //  Only events of the type MyEvent will be handled
                    }
                    
                TextField("Offset", value: $cellDataModel.offset, formatter: tcFormatter).frame(minWidth: 100, idealWidth: 100, maxWidth: 100)
                    .onSubmit {
                        sheetModel.updates += 1
                    }
            }.padding()
            WrappedHStack(
                $cellDataModel.arguments
            ) { $item in
                VStack {
                    TextField(item.name, text: $item.value, axis: .horizontal)
                    .padding(3)
                    .fixedSize(horizontal: true, vertical: false)
                    .frame(minWidth: 50, idealWidth: 100)
                    

//                    .focused(focus, equals: focusOrderedArguments.argumentMap[item])
//                    .onSubmit {
//                        updateFocus(item: item)
//                    }
                    Text(item.name)
                }.padding().border(config.cellBorder, width: 1).foregroundColor(config.cellFG)
                    
            }.frame(alignment: .topLeading)
        }.textFieldStyle(.plain)
            .frame(maxHeight: .infinity, alignment: .topLeading)
            .border(config.cellBorder, width: 4)
//            .focused(columnInFocus, equals: parentColumn)
//            .focused(cellInFocus, equals: cellDataModel)
            .setOnset($cellDataModel.onset)
            .setOffset($cellDataModel.offset)
            .frame(width: CGFloat(config.defaultCellWidth))
            .fixedSize(horizontal: true, vertical: false)
            .foregroundColor(config.cellFG)
            .background(config.cellBG)
            
    }
}
//
//extension Cell {
//    func keyboardUpDownSubscribe() {
//        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { (aEvent) -> NSEvent? in
//            print(aEvent.keyCode)
//            
//            switch aEvent.keyCode {
//            case 48:
//                print("FIRING")
//                nextCellEvent(FocusCellEvent(colIdx: 0, cellIdx: 1))
//            default:
//                break
//            }
//            
//            return aEvent
//        }
//    }
//    
//    private enum Field: Int, CaseIterable {
//        case f1, f2, f3, f4
//    }
//    
//    private func focusPreviousField() {
//        focusedField = focusedField.map {
//            Field(rawValue: $0.rawValue - 1) ?? Field.allCases.first!
//        }
//    }
//    
//    private func focusNextField() {
//        focusedField = focusedField.map {
//            Field(rawValue: $0.rawValue + 1) ?? Field.allCases.last!
//        }
//    }
//}
