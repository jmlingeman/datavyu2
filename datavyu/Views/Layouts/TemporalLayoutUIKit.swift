import SwiftUI
import AppKit

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
            print("RELOADING DATA")
            let selectionIndexPath = collectionView.selectionIndexPaths.first
            print("SELECTED INDEX PATH: \(selectionIndexPath)")
            collectionView.reloadData()
            context.coordinator.connectCellResponders()
            print("RELOADED")
            if selectionIndexPath != nil {
                collectionView.selectItems(at: [selectionIndexPath!],
                                                scrollPosition: .centeredVertically)
                let item = collectionView.item(at: selectionIndexPath!) as! CellViewUIKit
                item.setSelected()
                
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
    
    init(sheetModel: SheetModel, parent: TemporalLayoutCollection, itemSize: NSSize) {
        self.sheetModel = sheetModel
        self.parent = parent
        self.itemSize = itemSize
    }
    
    func focusNextCell() {
        if focusedIndexPath == nil {
            focusedIndexPath = IndexPath(item: 0, section: 0)
        }
        
        let collectionView = (self.parent.scrollView.documentView as! TemporalCollectionAppKitView)
        let newFocusedIndexPath = IndexPath(item: focusedIndexPath!.item + 1, section: focusedIndexPath!.section)
        let cellItem = collectionView.item(at: newFocusedIndexPath) as? CellViewUIKit
        
        cellItem?.setSelected()
        collectionView.window?.makeFirstResponder(cellItem?.onset)
    }
    
    func connectCellResponders() {
        var prevCell: CellModel? = nil
        for (i, column) in sheetModel.columns.enumerated() {
            for (j, cell) in column.cells.enumerated() {
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
        return sheetModel.columns[section].cells.count + 1
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: .init(CellViewUIKit.identifier), for: indexPath) as! CellViewUIKit
        let cell = sheetModel.columns[indexPath.section].cells[indexPath.item]
        
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
            cell.onset.becomeFirstResponder()
            collectionView.selectionIndexPaths = [indexPaths.first!]
        }
    }
    
    func collectionView(_ collectionView: NSCollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>) {
        if indexPaths.count > 0 {
            let cell = collectionView.item(at: indexPaths.first!)!
            (cell as! CellViewUIKit).setDeselected()
        }
    }
    
    
    }
