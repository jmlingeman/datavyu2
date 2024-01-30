//
//  ArgumentCellView.swift
//  datavyu
//
//  Created by Jesse Lingeman on 1/30/24.
//

import Cocoa

class ArgumentCellView: NSCollectionViewItem {
    static let identifier: String = "ArgumentCellView"
    
    @IBOutlet var onset: NSTextField!
    @IBOutlet var offset: NSTextField!
    @IBOutlet var argumentsCollectionView: NSCollectionView!
    
    var cell: CellModel!
    
    init(cell: CellModel!) {
        self.onset = NSTextField(string: formatTimestamp(timestamp: cell.onset))
        self.offset = NSTextField(string: formatTimestamp(timestamp: cell.offset))
        self.argumentsCollectionView = NSCollectionView()
        self.cell = cell
        
        super.init(nibName: "ArgumentCellView", bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        argumentsCollectionView.delegate = self
        argumentsCollectionView.dataSource = self
        argumentsCollectionView.register(ArgumentView.self, forItemWithIdentifier: .init(ArgumentView.identifier))
    }
    
    
}

extension ArgumentCellView: NSCollectionViewDelegate {
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        print("Arg Clicked")
    }
}

extension ArgumentCellView: NSCollectionViewDataSource {
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return cell.arguments.count
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: .init(ArgumentView.identifier), for: indexPath) as! ArgumentView
        let argument = cell.arguments[indexPath.item]
        item.configureCell(with: argument)
                
        return item
    }
}

//extension ArgumentCellView: NSCollectionViewDelegateFlowLayout {
//    
//}
