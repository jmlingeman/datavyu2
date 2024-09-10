//
//  Header.swift
//  Datavyu2
//
//  Created by Jesse Lingeman on 7/7/24.
//

import AppKit
import Foundation
import SwiftUI

struct Header: View {
    @ObservedObject var columnModel: ColumnModel
    @ObservedObject var appState: AppState
    @Binding var columnList: [ColumnModel]
    static let reuseIdentifier: String = "header"

    var body: some View {
        GeometryReader { _ in
            HStack {
                ZStack {
                    EditableLabel($columnModel.columnName).font(.system(size: Config.defaultCellTextSize * appState.zoomFactor)).frame(alignment: .center)
                    VStack {
                        Toggle(isOn: $columnModel.isFinished, label: {
                            Image(systemName: "lock.fill")
                        }).onChange(of: $columnModel.isFinished.wrappedValue) { _ in
                            columnModel.update()
                        }.toggleStyle(CheckboxToggleStyle()).frame(maxWidth: .infinity, alignment: .bottomTrailing)
                            .font(.system(size: Config.defaultCellTextSize * appState.zoomFactor))
                    }
                }
            }
            .frame(width: Config.defaultCellWidth * appState.zoomFactor, height: Config.headerSize)
            .border(Color.black)
            .background(columnModel.isSelected ? Color.teal : columnModel.isFinished ? Color.green : Color.accentColor)
        }.frame(width: Config.defaultCellWidth * appState.zoomFactor, height: Config.headerSize)
            .onTapGesture {
                columnModel.sheetModel?.selectedCell = nil
                columnModel.sheetModel?.setSelectedColumn(model: columnModel)
                Logger.info("Set selected")
            }
            .onDrag {
                appState.draggingColumn = columnModel
                return NSItemProvider(object: String(columnModel.columnName) as NSString)
            }
            .onDrop(of: [UTType.text], delegate: DragRelocateDelegate(item: columnModel, listData: $columnList, current: $appState.draggingColumn))
    }
}

struct DragRelocateDelegate: DropDelegate {
    @ObservedObject var item: ColumnModel
    @Binding var listData: [ColumnModel]
    @Binding var current: ColumnModel?

    func dropEntered(info _: DropInfo) {
        if item != current {
            let from = listData.firstIndex(of: current!)!
            let to = listData.firstIndex(of: item)!
            if listData[to].columnName != current!.columnName {
                listData.move(fromOffsets: IndexSet(integer: from),
                              toOffset: to > from ? to + 1 : to)
            }
            item.update()
        }
    }

    func dropUpdated(info _: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info _: DropInfo) -> Bool {
        current = nil
        return true
    }
}

final class HeaderCell: NSView, NSCollectionViewElement {
    static let identifier: String = "header"
    var headerView: Header?
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        registerForDraggedTypes([.string])
    }

    @available(*, unavailable)
    @objc dynamic required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setView<Content>(_ newValue: Content) where Content: View {
        headerView = newValue as? Header
        for view in subviews {
            view.removeFromSuperview()
        }
        let view = NSHostingView(rootView: newValue)
        view.autoresizingMask = [.width, .height]
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        view.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        view.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        view.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }
}
