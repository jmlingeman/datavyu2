import AppKit
import SwiftUI

enum LastEditedField {
    case none
    case onset
    case offset
    case arguments
}

enum Layouts {
    case ordinal
    case temporal
}

class LayoutChoice: ObservableObject {
    @Published var layout = Layouts.ordinal

    func swapLayout() {
        if layout == Layouts.temporal {
            layout = Layouts.ordinal
        } else {
            layout = Layouts.temporal
        }
    }
}

struct SheetCollectionView: View {
    @EnvironmentObject var sheetModel: SheetModel
    @EnvironmentObject var appState: AppState
    var body: some View {
        ZStack {
            SheetLayoutCollection(sheetModel: sheetModel, layout: appState.layout, itemSize: NSSize(width: 100, height: 100))
            Button("Change Layout") {
                DispatchQueue.main.async {
                    appState.layout.swapLayout()
                    sheetModel.updateSheet()
                }
            }.keyboardShortcut(KeyboardShortcut("t", modifiers: .command)).hidden()
        }
    }
}

final class SheetCollectionAppKitView: NSCollectionView {
    @ObservedObject var sheetModel: SheetModel
    var parentScrollView: NSScrollView
    var currentLayout: LayoutChoice
    private var rightClickIndex: Int = NSNotFound
    var lastEditedArgument: Argument? = nil
    var floatingHeaders: [ColumnModel: NSHostingView<Header>] = [:]

    init(sheetModel: SheetModel, parentScrollView: NSScrollView, layout: LayoutChoice) {
        self.sheetModel = sheetModel
        self.parentScrollView = parentScrollView
        currentLayout = layout
        super.init(frame: .zero)
        let layout = OrdinalCollectionViewLayout(sheetModel: sheetModel, scrollView: parentScrollView)
        collectionViewLayout = layout
        isSelectable = true
    }

    func setOrdinalLayout() {
        print("Setting ordinal layout")
        let layout = OrdinalCollectionViewLayout(sheetModel: sheetModel, scrollView: parentScrollView)
        collectionViewLayout = layout
    }

    func setTemporalLayout() {
        print("Setting temporal layout")
        let layout = TemporalCollectionViewLayout(sheetModel: sheetModel, scrollView: parentScrollView)
        collectionViewLayout = layout
    }

    override func setFrameSize(_ newSize: NSSize) {
        var size = NSSize(width: newSize.width, height: newSize.height)
        if newSize.width != collectionViewLayout?.collectionViewContentSize.width {
            size.width = collectionViewLayout?.collectionViewContentSize.width ?? 0
        }
        super.setFrameSize(size)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func deselectAllCells() {
        for (i, column) in sheetModel.visibleColumns.enumerated() {
            for (j, _) in column.getSortedCells().enumerated() {
                let curCellItem = (parentScrollView.documentView as! SheetCollectionAppKitView).item(at: IndexPath(item: j, section: i)) as? CellViewUIKit
                curCellItem?.setDeselected()
            }
        }
    }

//    func setResponderChain() {
//        let currentIndex = IndexPath(item: 0, section: 0)
//        var indexSet = Set<IndexPath>()
//        let newIndex = IndexPath(item: currentIndex.item + 1, section: currentIndex.section)
//        indexSet.insert(newIndex)
//        self.animator().selectItems(at: indexSet, scrollPosition: NSCollectionView.ScrollPosition.top)
//    }
//
    override func keyDown(with _: NSEvent) {
        print("AAAA")
//        setResponderChain()
    }
}

final class HeaderCell: NSView, NSCollectionViewElement {
    static let identifier: String = "header"
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }

    @available(*, unavailable)
    @objc dynamic required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setView<Content>(_ newValue: Content) where Content: View {
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

class ColumnSelected: ObservableObject {
    @Published var isSelected: Bool = false
}

struct Header: View {
    @ObservedObject var columnModel: ColumnModel
    static let reuseIdentifier: String = "header"

    var body: some View {
        GeometryReader { _ in
            HStack {
                VStack {
                    EditableLabel($columnModel.columnName)
                    Toggle(isOn: $columnModel.isFinished, label: {
                        Text("Finished")
                    }).onChange(of: $columnModel.isFinished.wrappedValue) {
                        columnModel.update()
                    }.toggleStyle(CheckboxToggleStyle()).frame(maxWidth: .infinity, alignment: .topTrailing)
                }
            }
            .frame(width: Config().defaultCellWidth, height: Config().headerSize)
            .border(Color.black)
            .background(columnModel.isSelected ? Color.teal : columnModel.isFinished ? Color.green : Color.accentColor)
        }.frame(width: Config().defaultCellWidth, height: Config().headerSize)
            .onTapGesture {
                columnModel.sheetModel.selectedCell = nil
                columnModel.sheetModel.setSelectedColumn(model: columnModel)
                print("Set selected")
            }
    }
}

struct SheetLayoutCollection: NSViewRepresentable {
    @ObservedObject var sheetModel: SheetModel
    @ObservedObject var layout: LayoutChoice
    var itemSize: NSSize

    @State var oldSheetModel: SheetModel?

    @State var scrollView: NSScrollView = .init()

    // MARK: - Coordinator for Delegate & Data Source & Flow Layout

    func makeCoordinator() -> Coordinator {
        Coordinator(sheetModel: sheetModel, parent: self, itemSize: itemSize)
    }

    // MARK: - NSViewRepresentable

    func makeNSView(context: Context) -> some NSScrollView {
        scrollView = NSScrollView()
        let collectionView = SheetCollectionAppKitView(sheetModel: sheetModel, parentScrollView: scrollView, layout: layout)
//        oldSheetModel = sheetModel
        collectionView.delegate = context.coordinator
        collectionView.dataSource = context.coordinator
        collectionView.allowsEmptySelection = true
        collectionView.allowsMultipleSelection = true
        collectionView.isSelectable = true

        collectionView.register(CellViewUIKit.self, forItemWithIdentifier: .init(CellViewUIKit.identifier))
        collectionView.register(HeaderCell.self, forSupplementaryViewOfKind: "header", withIdentifier: .init(HeaderCell.identifier))

        scrollView.documentView = collectionView
        scrollView.hasHorizontalScroller = true

        context.coordinator.connectCellResponders()

        if layout.layout == Layouts.ordinal {
            collectionView.setOrdinalLayout()
        } else {
            collectionView.setTemporalLayout()
        }

        return scrollView
    }

    func updateNSView(_ nsView: NSViewType, context: Context) {
        print("Trying to reload data...")

        if sheetModel != oldSheetModel {
            print("Sheet model changed")
        }

        if let collectionView = nsView.documentView as? SheetCollectionAppKitView {
            if (collectionView.collectionViewLayout as! TemporalCollectionViewLayout).layout != layout.layout {
                if layout.layout == Layouts.ordinal {
                    collectionView.setOrdinalLayout()
                } else {
                    collectionView.setTemporalLayout()
                }
            }

            for (i, column) in sheetModel.visibleColumns.enumerated() {
                let floatingHeader = NSHostingView(rootView: Header(columnModel: sheetModel.visibleColumns[i]))
                floatingHeader.frame = NSRect(origin: NSPoint(x: Int(Config().defaultCellWidth) * i, y: 0), size: NSSize(width: Config().defaultCellWidth, height: Config().headerSize))

                if !collectionView.floatingHeaders.keys.contains(where: { c in
                    c == column
                }) {
                    collectionView.floatingHeaders[column] = floatingHeader
                    scrollView.addFloatingSubview(floatingHeader, for: .vertical)
                }
            }

            context.coordinator.itemSize = itemSize
            var selectionIndexPath = collectionView.selectionIndexPaths.first

            var argIndexPath: IndexPath? = nil
            var lastEditedField = LastEditedField.onset
            if selectionIndexPath != nil {
                let curCellItem = context.coordinator.getCell(ip: selectionIndexPath!)
                lastEditedField = curCellItem?.lastEditedField ?? LastEditedField.onset
            }

            // If the cell's onset or offset changes, we gotta find it again
            // so we can re-highlight it.
            var curCellModel: CellModel?

            // Do the actual reload, erasing all view cell data

            print("Reloading")
            collectionView.reloadData()

//            DispatchQueue.main.async {
            // Figure out which view cell to select again
            if sheetModel.selectedCell != nil {
                curCellModel = sheetModel.selectedCell
            } else {
                return
            }

            var curCellIndexPath: IndexPath? = nil
            if curCellModel != nil {
                curCellIndexPath = sheetModel.findCellIndexPath(cell_to_find: curCellModel!)
            }

            // Figure out which field in the view cell to select
            if curCellIndexPath != nil {
                if lastEditedField == LastEditedField.none {
                    argIndexPath = IndexPath(item: -2, section: 0)
                } else if lastEditedField == LastEditedField.onset {
                    argIndexPath = IndexPath(item: -1, section: 0)
                } else if lastEditedField == LastEditedField.offset {
                    argIndexPath = IndexPath(item: 0, section: 0)
                } else {
                    argIndexPath = curCellModel?.getArgumentIndex(collectionView.lastEditedArgument!)
                }
                print("Focusing field: \(argIndexPath) for cell \(curCellIndexPath)")

                if argIndexPath!.item > curCellModel!.arguments.count - 1 {
                    print("Focusing next cell")
                    context.coordinator.focusNextCell(curCellIndexPath!)
                    print("Done focusing next cell")
                } else {
                    print("Focusing cell and args \(curCellIndexPath)")
                    context.coordinator.focusCell(curCellIndexPath!)
                    context.coordinator.focusField(argIndexPath)
                    print("Done focusing arguments")
                }
            } else {
                print("WARNING: LOST FOCUSED CELL")
            }
//            }
        }
    }
}

class Coordinator: NSObject, NSCollectionViewDelegate, NSCollectionViewDataSource, NSCollectionViewDelegateFlowLayout {
    @ObservedObject var sheetModel: SheetModel
    var parent: SheetLayoutCollection
    var itemSize: NSSize
    var cellItemMap = [CellModel: NSCollectionViewItem]()

    init(sheetModel: SheetModel, parent: SheetLayoutCollection, itemSize: NSSize) {
        self.sheetModel = sheetModel
        self.parent = parent
        self.itemSize = itemSize
    }

    func getCurrentCell() -> CellViewUIKit? {
        print(#function)

        let collectionView = (parent.scrollView.documentView as! SheetCollectionAppKitView)

        var ip: IndexPath? = IndexPath(item: 0, section: 0)
        if sheetModel.selectedCell != nil {
            ip = sheetModel.findCellIndexPath(cell_to_find: sheetModel.selectedCell!) ?? IndexPath(item: 0, section: 0)
        }
        let cellItem = collectionView.item(at: ip!) as? CellViewUIKit

        return cellItem
    }

    func getCell(ip: IndexPath) -> CellViewUIKit? {
        print(#function)

        let collectionView = (parent.scrollView.documentView as! SheetCollectionAppKitView)
        let cellItem = collectionView.item(at: ip) as? CellViewUIKit
        return cellItem
    }

    func getCell(cellModel: CellModel) -> CellViewUIKit? {
        print(#function)

        let collectionView = (parent.scrollView.documentView as! SheetCollectionAppKitView)
        let ip = sheetModel.findCellIndexPath(cell_to_find: cellModel)

        if ip != nil {
            let cellItem = collectionView.item(at: ip!) as? CellViewUIKit
            return cellItem
        } else {
            return nil
        }
    }

    func setCellSelected(cellModel: CellModel) {
        let ip = sheetModel.findCellIndexPath(cell_to_find: cellModel)
        if ip != nil {
            let collectionView = (parent.scrollView.documentView as! SheetCollectionAppKitView)
            sheetModel.setSelectedCell(selectedCell: cellModel)
            collectionView.selectionIndexPaths = Set([ip!])
        }
    }

    func focusNextCell(_ currentCellIp: IndexPath) {
        print(#function)
        let nextCellIp = IndexPath(item: currentCellIp.item + 1, section: currentCellIp.section)
        focusCell(nextCellIp)
    }

    func focusPrevCell(_ currentCellIp: IndexPath) {
        print(#function)
        let nextCellIp = IndexPath(item: currentCellIp.item - 1, section: currentCellIp.section)
        focusCell(nextCellIp)
    }

    func focusCell(_ ip: IndexPath) {
        print(#function)

        let collectionView = (parent.scrollView.documentView as! SheetCollectionAppKitView)

        var item = ip.item
        var section = ip.section

        if sheetModel.visibleColumns.count > 0, item >= sheetModel.visibleColumns[section].cells.count {
            print("Selecting next column")
            item = 0
            section = section + 1
            if section >= sheetModel.visibleColumns.count {
                section = 0
            }
        }
        let corrected_ip = IndexPath(item: item, section: section)
        let cellItem = collectionView.item(at: corrected_ip) as? CellViewUIKit

        cellItem?.setSelected()

        if cellItem != nil {
            sheetModel.setSelectedCell(selectedCell: cellItem?.cell)
        }

        collectionView.selectionIndexPaths = Set([corrected_ip])
        collectionView.animator().scrollToItems(at: Set([corrected_ip]), scrollPosition: [.bottom])
        cellItem?.focusOnset()
    }

    func focusField(_ ip: IndexPath?) {
        print(#function)
        let collectionView = (parent.scrollView.documentView as! SheetCollectionAppKitView)

        if ip == nil || sheetModel.selectedCell == nil {
            return
        }

        print("Focusing field \(ip?.item)")

        let cellIp = sheetModel.findCellIndexPath(cell_to_find: sheetModel.selectedCell!)
        let cellItem = collectionView.item(at: cellIp!) as? CellViewUIKit

        cellItem?.setSelected()

        if ip?.item == -2 {
            cellItem?.focusOnset()
        } else if ip?.item == -1 {
            cellItem?.focusOffset()
        } else {
            cellItem?.focusArgument(ip!)
        }
    }

    func connectCellResponders() {
        var prevCell: CellModel? = nil
        for (i, column) in sheetModel.visibleColumns.enumerated() {
            for (j, cell) in column.getSortedCells().enumerated() {
                if prevCell != nil {
                    //                        let prevCellItem = cellItemMap[prevCell!]
                    let prevCellItem = (parent.scrollView.documentView as! SheetCollectionAppKitView).item(at: IndexPath(item: j - 1, section: i)) as? CellViewUIKit
                    let curCellItem = (parent.scrollView.documentView as! SheetCollectionAppKitView).item(at: IndexPath(item: j, section: i)) as? CellViewUIKit

                    if prevCellItem != nil {
                        prevCellItem?.nextResponder = curCellItem
                    }
                }
                prevCell = cell
            }
        }
    }

    func numberOfSections(in _: NSCollectionView) -> Int {
        sheetModel.visibleColumns.count
    }

    func collectionView(_: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        sheetModel.visibleColumns[section].getSortedCells().count + 1
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: .init(CellViewUIKit.identifier), for: indexPath) as! CellViewUIKit
        let cell = sheetModel.visibleColumns[indexPath.section].getSortedCells()[indexPath.item]

        item.configureCell(cell, parentView: parent.scrollView.documentView as? SheetCollectionAppKitView)
        return item
    }

    func collectionView(_ collectionView: NSCollectionView, viewForSupplementaryElementOfKind kind: NSCollectionView.SupplementaryElementKind, at indexPath: IndexPath) -> NSView {
        print(#function)
        let item = collectionView.makeSupplementaryView(ofKind: kind, withIdentifier: .init(HeaderCell.identifier), for: indexPath) as! HeaderCell

        if sheetModel.visibleColumns.count > 0 {
            item.setView(Header(columnModel: sheetModel.visibleColumns[indexPath.section]))

//            let floatingHeader = NSHostingView(rootView: Header(columnModel: sheetModel.visibleColumns[indexPath.section]))
//            floatingHeader.frame = item.frame
//
//            let column = sheetModel.visibleColumns[indexPath.section]
//
//            if let sheetCollectionView = (collectionView as? SheetCollectionAppKitView) {
//                if !sheetCollectionView.floatingHeaders.keys.contains(where: { c in
//                    c == column
//                }) {
//                    sheetCollectionView.floatingHeaders[column] = floatingHeader
//                }
//            }
//            parent.scrollView.addFloatingSubview(floatingHeader, for: .vertical)

            return item
        } else {
            return item
        }
    }

    func collectionView(_: NSCollectionView, layout _: NSCollectionViewLayout, sizeForItemAt _: IndexPath) -> NSSize {
        parent.itemSize
    }

    func collectionView(_: NSCollectionView, layout _: NSCollectionViewLayout, minimumLineSpacingForSectionAt _: Int) -> CGFloat {
        100
    }

    func collectionView(_: NSCollectionView, layout _: NSCollectionViewLayout, minimumInteritemSpacingForSectionAt _: Int) -> CGFloat {
        100
    }

    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        print(#function)
        print(indexPaths)
        if indexPaths.count > 0 {
            let cell = collectionView.item(at: indexPaths.first!) as! CellViewUIKit
            cell.setSelected()
            collectionView.selectionIndexPaths = Set([indexPaths.first!])
        }
    }

    func collectionView(_ collectionView: NSCollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>) {
        if indexPaths.count > 0 {
            print("DESELECTING \(indexPaths.first!)")
            let cell = collectionView.item(at: indexPaths.first!)
            if cell != nil {
                (cell! as! CellViewUIKit).setDeselected()
            }
        }
    }
}
