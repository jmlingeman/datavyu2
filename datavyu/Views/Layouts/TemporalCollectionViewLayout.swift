//
//  TemporalCollectionViewLayout.swift
//  datavyu
//
//  Created by Jesse Lingeman on 12/29/23.
//

import Foundation
import AppKit
import SwiftUI

class TemporalCollectionViewLayout: NSCollectionViewLayout {
    override var collectionViewContentSize: NSSize
    @ObservedObject var sheetModel: SheetModel
    
    init(sheetModel: SheetModel, collectionViewContentSize: NSSize) {
        self.sheetModel = sheetModel
        self.collectionViewContentSize = collectionViewContentSize
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepare() {
        
    }
    
    override func layoutAttributesForElements(in rect: NSRect) -> [NSCollectionViewLayoutAttributes] {
        
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> NSCollectionViewLayoutAttributes? {
        
    }
    
    override func layoutAttributesForSupplementaryView(ofKind elementKind: NSCollectionView.SupplementaryElementKind, at indexPath: IndexPath) -> NSCollectionViewLayoutAttributes? {
        
    }
    
    override func layoutAttributesForDecorationView(ofKind elementKind: NSCollectionView.DecorationElementKind, at indexPath: IndexPath) -> NSCollectionViewLayoutAttributes? {
        
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: NSRect) -> Bool {
        
    }
    
    override func initialLayoutAttributesForAppearingItem(at itemIndexPath: IndexPath) -> NSCollectionViewLayoutAttributes? {
        
    }
    
    override func finalLayoutAttributesForDisappearingItem(at itemIndexPath: IndexPath) -> NSCollectionViewLayoutAttributes? {
        
    }
}
