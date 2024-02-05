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
    
    func setResponderChain() {
        let currentIndex = IndexPath(item: 0, section: 0)
        var indexSet = Set<IndexPath>()
        let newIndex = IndexPath(item: currentIndex.item + 1, section: currentIndex.section)
        indexSet.insert(newIndex)
        self.animator().selectItems(at: indexSet, scrollPosition: NSCollectionView.ScrollPosition.top)
    }
    
    override func keyDown(with event: NSEvent) {
        print("AAAA")
        setResponderChain()
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
    
    class Coordinator: NSObject, NSCollectionViewDelegate, NSCollectionViewDataSource, NSCollectionViewDelegateFlowLayout {
        @ObservedObject var sheetModel: SheetModel
        var parent: TemporalLayoutCollection
        var itemSize: NSSize
        var cellItemMap = [CellModel: NSCollectionViewItem]()
        
        init(sheetModel: SheetModel, parent: TemporalLayoutCollection, itemSize: NSSize) {
            self.sheetModel = sheetModel
            self.parent = parent
            self.itemSize = itemSize
        }
        
        //        func connectCellResponders() {
        //            var prevCell: CellModel? = nil
        //            for column in sheetModel.columns {
        //                for cell in column.cells {
        //                    if prevCell != nil {
        //                        print(cellItemMap[prevCell!])
        //                        let prevCellItem = cellItemMap[prevCell!]
        //                        if prevCellItem != nil {
        //                            for subview in prevCellItem!.view.subviews {
        //                                subview.nextResponder = cellItemMap[cell]
        //                            }
        //                            cellItemMap[prevCell!]?.nextResponder = cellItemMap[cell]
        //                            cellItemMap[prevCell!]?.view.nextResponder = cellItemMap[cell]?.view
        //                        }
        //
        //                    }
        //                    prevCell = cell
        //                }
        //            }
        //        }
        
        func numberOfSections(in collectionView: NSCollectionView) -> Int {
            return sheetModel.columns.count
        }
        
        func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
            return sheetModel.columns[section].cells.count + 1
        }
        
        func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
            let item = collectionView.makeItem(withIdentifier: .init(CellViewUIKit.identifier), for: indexPath) as! CellViewUIKit
            let cell = sheetModel.columns[indexPath.section].cells[indexPath.item]

            item.configureCell(cell)
            
//            print("CREATING CELL AT \(indexPath.section) \(indexPath.item) \(Unmanaged.passUnretained(cell).toOpaque())")
            print("Setting cell \(cell.column.columnName) \(cell.ordinal) \(cell.onset) \(cell.offset) \(cell.arguments[0].value)")
            cellItemMap[cell] = item
            
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
    }
        
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(sheetModel: self.sheetModel, parent: self, itemSize: itemSize)
    }
    
    // MARK: - NSViewRepresentable
    
    func makeNSView(context: Context) -> some NSScrollView {
//        let scrollView = NSScrollView()
        let collectionView = TemporalCollectionAppKitView(sheetModel: sheetModel, parentScrollView: scrollView)
        collectionView.delegate = context.coordinator
        collectionView.dataSource = context.coordinator
        collectionView.allowsEmptySelection = false
        collectionView.allowsMultipleSelection = true
        collectionView.isSelectable = true
        
        collectionView.register(CellViewUIKit.self, forItemWithIdentifier: .init(CellViewUIKit.identifier))
        collectionView.register(HeaderCell.self, forSupplementaryViewOfKind: "header", withIdentifier: .init(HeaderCell.identifier))
                        
        scrollView.documentView = collectionView
        scrollView.hasHorizontalScroller = true
                
        return scrollView
    }
    
    func updateNSView(_ nsView: NSViewType, context: Context) {
        print("Trying to reload data...")
        if let collectionView = nsView.documentView as? TemporalCollectionAppKitView {
            context.coordinator.itemSize = itemSize
            print("RELOADING DATA")
            collectionView.reloadData()
            print("RELOADED")
        }
    }
}
