import SwiftUI
import AppKit

class TemporalCollectionView: NSCollectionView {
    
    var sheetModel: SheetModel
    private var rightClickIndex: Int = NSNotFound
    
    init(sheetModel: SheetModel) {
        self.sheetModel = sheetModel
        super.init(frame: .zero)
        let layout = TemporalCollectionViewLayout(sheetModel: sheetModel)
        self.collectionViewLayout = layout
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        view.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        view.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        view.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        self.addSubview(view)
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
        .background(Color.purple)
    }
}

class CollectionCell: NSCollectionViewItem {
    static let identifier: String = "AppCollectionCell"
    
    override func loadView() {
        self.view = NSView()
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = .clear
    }
    
    func configureCell(_ article: CellModel, size: NSSize) {
        for v in self.view.subviews {
            v.removeFromSuperview()
        }
        let contentView = NSHostingView(rootView:
                                            Cell(cellDataModel: article)
        )
        contentView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(contentView)
        contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        contentView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }
}

struct TemporalLayoutCollection: NSViewRepresentable {
    @ObservedObject var sheetModel: SheetModel
    var itemSize: NSSize
    
    // MARK: - Coordinator for Delegate & Data Source & Flow Layout
    
    class Coordinator: NSObject, NSCollectionViewDelegate, NSCollectionViewDataSource, NSCollectionViewDelegateFlowLayout {
        @ObservedObject var sheetModel: SheetModel
        var parent: TemporalLayoutCollection
        var itemSize: NSSize
        
        init(parent: TemporalLayoutCollection, sheetModel: SheetModel, itemSize: NSSize) {
            self.parent = parent
            self.sheetModel = sheetModel
            self.itemSize = itemSize
        }
        
        func numberOfSections(in collectionView: NSCollectionView) -> Int {
            return sheetModel.columns.count
        }
        
        func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
            return sheetModel.columns[section].cells.count + 1
        }
        
        func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
            let item = collectionView.makeItem(withIdentifier: .init(CollectionCell.identifier), for: indexPath) as! CollectionCell
            let cell = sheetModel.columns[indexPath.section].cells[indexPath.item]
            item.configureCell(cell, size: itemSize)
            return item
        }
        
        func collectionView(_ collectionView: NSCollectionView, viewForSupplementaryElementOfKind kind: NSCollectionView.SupplementaryElementKind, at indexPath: IndexPath) -> NSView {
            let item = collectionView.makeSupplementaryView(ofKind: kind, withIdentifier: .init(HeaderCell.identifier), for: indexPath) as! HeaderCell
            item.setView(Header(columnModel: $sheetModel.columns[indexPath.section]))
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
        return Coordinator(parent: self, sheetModel: sheetModel, itemSize: itemSize)
    }
    
    // MARK: - NSViewRepresentable
    
    func makeNSView(context: Context) -> some NSScrollView {
        let collectionView = TemporalCollectionView(sheetModel: sheetModel)
        collectionView.delegate = context.coordinator
        collectionView.dataSource = context.coordinator
        collectionView.allowsEmptySelection = false
        collectionView.allowsMultipleSelection = false
        collectionView.isSelectable = false
        
        collectionView.register(CollectionCell.self, forItemWithIdentifier: .init(CollectionCell.identifier))
        collectionView.register(HeaderCell.self, forSupplementaryViewOfKind: "header", withIdentifier: .init(HeaderCell.identifier))
        
        let scrollView = NSScrollView()
        scrollView.documentView = collectionView
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSViewType, context: Context) {
        if let collectionView = nsView.documentView as? TemporalCollectionView {
            collectionView.sheetModel = sheetModel
            context.coordinator.sheetModel = sheetModel
            context.coordinator.itemSize = itemSize
            collectionView.reloadData()
        }
    }
}
