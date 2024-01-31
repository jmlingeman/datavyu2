//
//  ArgumentCellView.swift
//  datavyu
//
//  Created by Jesse Lingeman on 1/30/24.
//

import Cocoa
import SwiftUI

class CellViewUIKit: NSCollectionViewItem {
    static let identifier: String = "CellViewUIKit"
    
    @IBOutlet var onset: NSTextField!
    @IBOutlet var offset: NSTextField!
    @IBOutlet var ordinal: NSTextField!
    @IBOutlet var argumentsCollectionView: NSCollectionView!
    
    @ObservedObject var cell: CellModel
    
    override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?) {
        self.cell = CellModel()
        self.ordinal = NSTextField()
        self.onset = NSTextField()
        self.offset = NSTextField()
        self.argumentsCollectionView = NSCollectionView()
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureCell(_ cell: CellModel) {
        self.cell = cell
        self.ordinal.stringValue = String(cell.ordinal)
        self.onset.stringValue = formatTimestamp(timestamp: cell.onset)
        self.offset.stringValue = formatTimestamp(timestamp: cell.offset)
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        self.argumentsCollectionView.register(ArgumentViewUIKit.self, forItemWithIdentifier: .init(ArgumentViewUIKit.identifier))
        self.argumentsCollectionView.delegate = self
        self.argumentsCollectionView.dataSource = self
    }
        
}

extension CellViewUIKit: NSCollectionViewDelegate {
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        print("Arg Clicked")
    }
}

extension CellViewUIKit: NSCollectionViewDataSource {
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return cell.arguments.count
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: .init(ArgumentViewUIKit.identifier), for: indexPath) as! ArgumentViewUIKit
        let argument = cell.arguments[indexPath.item]
        item.configureCell(with: argument)
        
        print("CREATING CELL")
                
        return item
    }
}

//extension ArgumentCellView: NSCollectionViewDelegateFlowLayout {
//    
//}
