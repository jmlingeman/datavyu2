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
        var parent: TemporalLayoutCollection
        var cells: [CellModel]
        var itemSize: NSSize
        
        init(parent: TemporalLayoutCollection, cells: [CellModel], itemSize: NSSize) {
            self.parent = parent
            self.cells = cells
            self.itemSize = itemSize
        }
        
        func numberOfSections(in collectionView: NSCollectionView) -> Int {
            return 1
        }
        
        func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
            return cells.count
        }
        
        func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
            let item = collectionView.makeItem(withIdentifier: .init(CollectionCell.identifier), for: indexPath) as! CollectionCell
            let cell = cells[indexPath.item]
            item.configureCell(cell, size: itemSize)
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
        return Coordinator(parent: self, cells: sheetModel.columns[0].getSortedCells(), itemSize: itemSize)
    }
    
    // MARK: - NSViewRepresentable
    
    func makeNSView(context: Context) -> some NSScrollView {
        let collectionView = TemporalCollectionView(sheetModel: sheetModel)
        collectionView.delegate = context.coordinator
        collectionView.dataSource = context.coordinator
        collectionView.allowsEmptySelection = false
        collectionView.allowsMultipleSelection = false
        collectionView.isSelectable = false
        let scrollView = NSScrollView()
        scrollView.documentView = collectionView
        collectionView.register(CollectionCell.self, forItemWithIdentifier: .init(CollectionCell.identifier))
        return scrollView
    }
    
    func updateNSView(_ nsView: NSViewType, context: Context) {
        if let collectionView = nsView.documentView as? TemporalCollectionView {
            collectionView.sheetModel = sheetModel
            context.coordinator.cells = sheetModel.columns[0].getSortedCells()
            context.coordinator.itemSize = itemSize
            collectionView.reloadData()
        }
    }
}
