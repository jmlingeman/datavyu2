import SwiftUI
import AppKit

enum LastEditedField {
    case none
    case onset
    case offset
    case arguments
}

struct TemporalCollectionView: View {
    @EnvironmentObject var sheetModel: SheetModel
    var body: some View {
        VStack {
            TemporalLayoutCollection(sheetModel: sheetModel, itemSize: NSSize(width: 100, height: 100))
        }
    }
}

final class TemporalCollectionAppKitView: NSCollectionView {
    
    @ObservedObject var sheetModel: SheetModel
    var parentScrollView: NSScrollView
    private var rightClickIndex: Int = NSNotFound
    var lastSelectedCellModel: CellModel? = nil
    
    init(sheetModel: SheetModel, parentScrollView: NSScrollView) {
        self.sheetModel = sheetModel
        self.parentScrollView = parentScrollView
        super.init(frame: .zero)
        let layout = TemporalCollectionViewLayout(sheetModel: sheetModel, scrollView: parentScrollView)
        self.collectionViewLayout = layout
        self.isSelectable = true
    }
        
    override func setFrameSize(_ newSize: NSSize) {
        var size = NSSize(width: newSize.width, height: newSize.height)
        if newSize.width != self.collectionViewLayout?.collectionViewContentSize.width {
            size.width = self.collectionViewLayout?.collectionViewContentSize.width ?? 0
        }
        super.setFrameSize(size)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func deselectAllCells() {
        for (i, column) in sheetModel.columns.enumerated() {
            for (j, _) in column.getSortedCells().enumerated() {
                let curCellItem = (parentScrollView.documentView as! TemporalCollectionAppKitView).item(at: IndexPath(item: j, section: i)) as? CellViewUIKit
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
    override func keyDown(with event: NSEvent) {
        print("AAAA")
//        setResponderChain()
    }
            
}

final class HeaderCell: NSView, NSCollectionViewElement {
    static let identifier: String = "header"
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }
    @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func setView<Content>(_ newValue: Content) where Content: View {
        for view in self.subviews {
            view.removeFromSuperview()
        }
        let view = NSHostingView(rootView: newValue)
        view.autoresizingMask = [.width, .height]
        view.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(view)
        view.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        view.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        view.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }
}

struct Header: View {
    @Binding var columnModel: ColumnModel
    static let reuseIdentifier: String = "header"
    
    var body: some View {
        HStack {
            EditableLabel($columnModel.columnName)
        }
        .frame(width: Config().defaultCellWidth, height: Config().headerSize)
        .border(Color.black)
        .background(Color.accentColor)
    }
}

struct TemporalLayoutCollection: NSViewRepresentable {
    @ObservedObject var sheetModel: SheetModel
    var itemSize: NSSize
    
    var scrollView: NSScrollView = NSScrollView()
    
    
    // MARK: - Coordinator for Delegate & Data Source & Flow Layout
    

        
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(sheetModel: self.sheetModel, parent: self, itemSize: itemSize)
    }
    
    // MARK: - NSViewRepresentable
    
    func makeNSView(context: Context) -> some NSScrollView {
//        let scrollView = NSScrollView()
        let collectionView = TemporalCollectionAppKitView(sheetModel: sheetModel, parentScrollView: scrollView)
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
                
        return scrollView
    }
    
    func updateNSView(_ nsView: NSViewType, context: Context) {
        print("Trying to reload data...")

        if let collectionView = nsView.documentView as? TemporalCollectionAppKitView {
            context.coordinator.itemSize = itemSize
            var selectionIndexPath = collectionView.selectionIndexPaths.first
            
            var argIndexPath: IndexPath? = nil
            var lastEditedField: LastEditedField = LastEditedField.onset
            if selectionIndexPath != nil {
                let curCellItem = context.coordinator.getCell(ip: selectionIndexPath!)
                lastEditedField = curCellItem?.lastEditedField ?? LastEditedField.onset
                let curArgIndex = curCellItem?.argumentsCollectionView.selectionIndexPaths.first
                argIndexPath = IndexPath(item: (curArgIndex?.item ?? 0) + 1, section: curArgIndex?.section ?? 0)
            }
            
            // If the cell's onset or offset changes, we gotta find it again
            // so we can re-highlight it.
            let curCell = context.coordinator.getCell(ip: selectionIndexPath ?? IndexPath(item: 0, section: 0))
            var curCellModel: CellModel? = curCell?.cell ?? nil
            

            // Do the actual reload, erasing all view cell data
            collectionView.reloadData()
            

            
            DispatchQueue.main.async {
                // Figure out which view cell to select again
                if collectionView.lastSelectedCellModel != nil {
                    curCellModel = collectionView.lastSelectedCellModel
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
                    print("ERROR LOST FOCUSED CELL")
                }
            }
            
        }
    }
}

class Coordinator: NSObject, NSCollectionViewDelegate, NSCollectionViewDataSource, NSCollectionViewDelegateFlowLayout {
    @ObservedObject var sheetModel: SheetModel
    var parent: TemporalLayoutCollection
    var itemSize: NSSize
    var cellItemMap = [CellModel: NSCollectionViewItem]()
    var focusedCell: CellViewUIKit?
    var focusedIndexPath: IndexPath?
    var focusedField: NSView?
        
    
    init(sheetModel: SheetModel, parent: TemporalLayoutCollection, itemSize: NSSize) {
        self.sheetModel = sheetModel
        self.parent = parent
        self.itemSize = itemSize
    }
    
    
    
    func getCurrentCell() -> CellViewUIKit? {
        print(#function)
        if focusedIndexPath == nil {
            focusedIndexPath = IndexPath(item: 0, section: 0)
        }
        
        let collectionView = (self.parent.scrollView.documentView as! TemporalCollectionAppKitView)
        let focusedIndexPath = IndexPath(item: focusedIndexPath!.item, section: focusedIndexPath!.section)
        let cellItem = collectionView.item(at: focusedIndexPath) as? CellViewUIKit
        
        return cellItem
    }
    
    func getCell(ip: IndexPath) -> CellViewUIKit? {
        print(#function)
        
        let collectionView = (self.parent.scrollView.documentView as! TemporalCollectionAppKitView)
        let cellItem = collectionView.item(at: ip) as? CellViewUIKit
        return cellItem
    }
    
    func getCell(cellModel: CellModel) -> CellViewUIKit? {
        print(#function)
        
        let collectionView = (self.parent.scrollView.documentView as! TemporalCollectionAppKitView)
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
            let collectionView = (self.parent.scrollView.documentView as! TemporalCollectionAppKitView)
            collectionView.lastSelectedCellModel = cellModel
            collectionView.selectionIndexPaths = Set([ip!])
        }
    }
    
    func focusNextCell(_ currentCellIp: IndexPath) {
        print(#function)
        let nextCellIp = IndexPath(item: currentCellIp.item+1, section: currentCellIp.section)
        focusCell(nextCellIp)
    }
    
    func focusCell(_ ip: IndexPath) {
        print(#function)
        
        let collectionView = (self.parent.scrollView.documentView as! TemporalCollectionAppKitView)
        
        var item = ip.item
        var section = ip.section
        
        if item >= sheetModel.columns[section].cells.count {
            print("Selecting next column")
            item = 0
            section = section + 1
            if section >= sheetModel.columns.count {
                section = 0
            }
        }
        
        let corrected_ip = IndexPath(item: item, section: section)
        let cellItem = collectionView.item(at: corrected_ip) as? CellViewUIKit
        
        cellItem?.setSelected()
        print("Focusing cell's onset \(collectionView.window) \(cellItem?.onset) \(corrected_ip)")
        cellItem?.focusOnset()
        
        focusedCell = cellItem
        focusedIndexPath = corrected_ip
//        collectionView.window?.makeFirstResponder(cellItem?.onset)
        collectionView.selectionIndexPaths = Set([corrected_ip])
        collectionView.lastSelectedCellModel = cellItem?.cell

        collectionView.scrollToItems(at: Set([corrected_ip]), scrollPosition: [.centeredVertically])
    }
    
    func focusNextField() {
        print(#function)
        if focusedIndexPath == nil {
            focusedIndexPath = IndexPath(item: 0, section: 0)
        }
        
        let collectionView = (self.parent.scrollView.documentView as! TemporalCollectionAppKitView)
        let cellItem = collectionView.item(at: focusedIndexPath!) as? CellViewUIKit
        
        cellItem?.focusNextArgument()
    }
    
    func focusField(_ ip: IndexPath?) {
        print(#function)
        if ip == nil {
            return
        }
        
        let collectionView = (self.parent.scrollView.documentView as! TemporalCollectionAppKitView)
        let cellItem = collectionView.item(at: focusedIndexPath!) as? CellViewUIKit
        
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
        for (i, column) in sheetModel.columns.enumerated() {
            for (j, cell) in column.getSortedCells().enumerated() {
                if prevCell != nil {
                    //                        let prevCellItem = cellItemMap[prevCell!]
                    let prevCellItem = (parent.scrollView.documentView as! TemporalCollectionAppKitView).item(at: IndexPath(item: j-1, section: i)) as? CellViewUIKit
                    let curCellItem = (parent.scrollView.documentView as! TemporalCollectionAppKitView).item(at: IndexPath(item: j, section: i)) as? CellViewUIKit
                    
                    if prevCellItem != nil {
                        prevCellItem?.nextResponder = curCellItem
                        //                            prevCellItem?.collectionView?.item(at: IndexPath(item: 0, section: 0))?.textField?.currentEditor()?.nextResponder = curCellItem?.onset
                        //                            prevCellItem?.collectionView?.item(at: IndexPath(item: 0, section: 0))?.textField?.currentEditor()?.nextKeyView = curCellItem?.onset
                        print(prevCellItem, prevCellItem?.collectionView?.item(at: IndexPath(item: 0, section: 0))?.nextResponder)
                    }
                    
                }
                prevCell = cell
            }
        }
    }
    
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return sheetModel.columns.count
    }
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return sheetModel.columns[section].getSortedCells().count + 1
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: .init(CellViewUIKit.identifier), for: indexPath) as! CellViewUIKit
        let cell = sheetModel.columns[indexPath.section].getSortedCells()[indexPath.item]
        
        item.configureCell(cell, parentView: parent.scrollView.documentView as? TemporalCollectionAppKitView)
        
        //            print("CREATING CELL AT \(indexPath.section) \(indexPath.item) \(Unmanaged.passUnretained(cell).toOpaque())")
        //            cellItemMap[cell] = item
        
        return item
    }
    
    func collectionView(_ collectionView: NSCollectionView, viewForSupplementaryElementOfKind kind: NSCollectionView.SupplementaryElementKind, at indexPath: IndexPath) -> NSView {
        let item = collectionView.makeSupplementaryView(ofKind: kind, withIdentifier: .init(HeaderCell.identifier), for: indexPath) as! HeaderCell
        item.setView(Header(columnModel: $sheetModel.columns[indexPath.section]))
        
        let floatingHeader = NSHostingView(rootView: Header(columnModel: $sheetModel.columns[indexPath.section]))
        floatingHeader.frame = item.frame
        parent.scrollView.addFloatingSubview(floatingHeader, for: .vertical)
        
        return item
    }
    
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        return parent.itemSize
    }
    
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 100
    }
    
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 100
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
            let cell = collectionView.item(at: indexPaths.first!)!
            (cell as! CellViewUIKit).setDeselected()
        }
    }
    
    
}
