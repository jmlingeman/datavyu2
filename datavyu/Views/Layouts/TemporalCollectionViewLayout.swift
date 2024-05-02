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
    var sheetModel: SheetModel
    var scrollView: NSScrollView
    var updateCount: Int = 0
    
    struct CellInfo: Hashable {
        let model: CellModel
        let columnIdx: Int
        let cellIdx: Int
    }
    
    struct CacheData {
        var indexToLayout: [IndexPath: NSCollectionViewLayoutAttributes]
        var maxHeight: CGFloat
        var maxWidth: CGFloat
        var cellLayouts: [CellInfo: NSCollectionViewLayoutAttributes]
        var headerLayouts: [Int: NSCollectionViewLayoutAttributes]
    }
    
    var cache: CacheData = CacheData(
        indexToLayout: [IndexPath : NSCollectionViewLayoutAttributes](),
        maxHeight: 0,
        maxWidth: 0,
        cellLayouts: [CellInfo: NSCollectionViewLayoutAttributes](),
        headerLayouts: [Int : NSCollectionViewLayoutAttributes]()
    )
    override var collectionViewContentSize: NSSize {
        get {
            return NSSize(width: cache.maxWidth, height: cache.maxHeight)
        }
    }
    
    init(sheetModel: SheetModel, scrollView: NSScrollView) {
        self.sheetModel = sheetModel
        self.scrollView = scrollView
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
    override func prepare() {
        print("PREPARING")
        
        let config = Config()
        let gapSize = config.gapSize
        let columnSize = config.defaultCellWidth
        let headerSize = config.headerSize
        
        
        var cellLayouts = [CellInfo: NSCollectionViewLayoutAttributes]()
        var headerLayouts = [Int : NSCollectionViewLayoutAttributes]()
        
        for (colIdx, column) in sheetModel.columns.enumerated() {
            for (cellIdx, cell) in column.getSortedCells().enumerated() {
                let cellInfo = CellInfo(model: cell, columnIdx: colIdx, cellIdx: cellIdx)
                cellLayouts[cellInfo] = NSCollectionViewLayoutAttributes(forItemWith: IndexPath(item: cellIdx, section: colIdx))
            }
            let headerLayout = NSCollectionViewLayoutAttributes(forSupplementaryViewOfKind: "header", with: IndexPath(item: -1, section: colIdx))
            headerLayout.frame.origin = CGPoint(x: Int(columnSize) * colIdx, y: 0)
            headerLayout.frame.size = CGSize(width: config.defaultCellWidth, height: config.headerSize)
            headerLayout.size = CGSize(width: config.defaultCellWidth, height: config.headerSize)
            headerLayouts[colIdx] = headerLayout
        }
        
        /*
         Idea: Loop through storing proposed positions
         Loop through again to fix the heights based on placed onsets/offsets
         */
        
        // Bookkeeping Hashmaps
        var sizes: [CellInfo: CGSize] = [:]
        var pts: [CellInfo: CGPoint] = [:]
        var heightMap: [Int: Double] = [:]
        var onsetToPos: [Int: Double] = [:]
        var offsetToPos: [Int: Double] = [:]
        
        // Assign defaults
        for subview in cellLayouts.keys {
            sizes[subview] = CGSize(width: columnSize, height: 0)
            pts[subview] = CGPoint(x: Int(columnSize) * subview.columnIdx, y: 0)
        }
        var times = Set<Int>()
        
        var columnViews: [Int: [CellInfo]] = [:]
        for subview in cellLayouts.keys {
            columnViews[subview.columnIdx, default: []].append(subview)
        }
        for colIdx in columnViews.keys {
            columnViews[colIdx] = columnViews[colIdx]?.sorted(by: {
                if $0.model.onset == $1.model.onset {
                    if $0.model.offset == $1.model.offset {
                        return $0.cellIdx < $1.cellIdx
                    }
                    return $0.model.offset < $1.model.offset
                }
                return $0.model.onset < $1.model.onset
            })
        }
        
        
        /* Go through each column and assign "height" values to onset times.
         This will determine how much space to allocate between onset times.
         For each column, create an intermediate map and then merge with the
         actual map using maximum values.  This is required since a column can have
         multiple cells with the same onset.
         Also accumulate all unique times.
         */
        
        
        
        for colIdx in columnViews.keys {
            var intermediateMap: [Int: Double] = [:]
            for cell in columnViews[colIdx]! {
                let height = Double(config.minCellHeight)
                let onset = cell.model.onset
                intermediateMap[onset] = intermediateMap[onset, default: 0] + height
                times.insert(cell.model.onset)
                if cell.model.offset > cell.model.onset {
                    times.insert(cell.model.offset)
                }
            }
            for onset in intermediateMap.keys {
                heightMap[onset] = max(heightMap[onset, default: 0], intermediateMap[onset]!)
            }
        }
        
        
        var pos = headerSize
        for time in Array(times).sorted() {
            onsetToPos[time] = pos
            pos += heightMap[time, default: 0]
            pos += gapSize
        }
        
        /* Iterate over all spreadsheet cells and set boundaries using onset and offset maps.
         Keep a local copy of the position maps.  Since each time value gets a range of positions
         (starting from onset map's value and ending at the offset's value), update the local copy of
         the onset map to get positions for cells sharing onsets.
         */
        for colIdx in columnViews.keys {
            var colHeight = 0.0
            var onsetMapLocal: [Int: Double] = onsetToPos
            var prevCell: CellInfo?
            let colCells = columnViews[colIdx]!
            for (idx, curCell) in colCells.enumerated() {
                var nextCell: CellInfo?
                if idx+1 < colCells.count {
                    nextCell = colCells[idx+1]
                }
                
                let onset = curCell.model.onset
                let offset = curCell.model.offset
                let cellTopY = onsetMapLocal[onset]!
                
                var cellHeight = 0.0
                if onset > offset {
                    // TODO: Set overlap border here
                    cellHeight = Double(config.minCellHeight)
                } else if nextCell != nil && onset == nextCell!.model.onset {
                    if onset != offset || offset == nextCell!.model.offset {
                        // TODO: Set overlap border here
                    }
                    cellHeight = Double(config.minCellHeight)
                } else if nextCell != nil && offset >= nextCell!.model.onset {
                    // TODO: Set overlap border here
                    cellHeight = onsetMapLocal[nextCell!.model.onset]! - cellTopY;
                } else {
                    cellHeight = offsetToPos[offset, default: onsetToPos[offset]!] - cellTopY;
                }
                
                if prevCell != nil && onset - prevCell!.model.offset == 1 {
                    sizes[prevCell!]!.height =  cellTopY - sizes[prevCell!]!.height
                    offsetToPos[offset] = max(offsetToPos[offset] ?? 0, cellTopY)
                }
                
                // fix for edge cases...maybe investigate later
                cellHeight = max(cellHeight, Double(config.minCellHeight));
                // Set cell boundary
                pts[curCell]?.y = cellTopY
                sizes[curCell]?.height = cellHeight
                
                // Update local onset map
                onsetMapLocal[onset] = onsetMapLocal[onset]! + cellHeight
                
                // Only do if we're not setting overlap
                if curCell.model.onset < curCell.model.offset {
                    offsetToPos[offset] = max(offsetToPos[offset, default: cellTopY + cellHeight], cellTopY + cellHeight)
                }
                
                // Update vars
                colHeight = cellTopY + cellHeight;
                prevCell = curCell;
            }
            
            cache.maxHeight = max(cache.maxHeight, colHeight)
        }
        
        var i = 0
        var indexToLayout = [IndexPath: NSCollectionViewLayoutAttributes]()
        for colIdx in columnViews.keys {
            
            let colCells = columnViews[colIdx]!
            for curCell in colCells {
                let mapHeight = offsetToPos[curCell.model.offset, default: -1] - pts[curCell]!.y
                if sizes[curCell]!.height < mapHeight {
                    sizes[curCell]?.height = mapHeight
                }
                cellLayouts[curCell]?.frame.origin = pts[curCell]!
                cellLayouts[curCell]?.frame.size = sizes[curCell]!
                cellLayouts[curCell]?.size = sizes[curCell]!
                
                indexToLayout[cellLayouts[curCell]!.indexPath!] = cellLayouts[curCell]
                
                i += 1
                
//                curCell.place(at: pts[curCell]!, proposal: ProposedViewSize(sizes[curCell]!))
            }
            
            indexToLayout[headerLayouts[colIdx]!.indexPath!] = headerLayouts[colIdx]
        }
        
        
        cache.indexToLayout = indexToLayout
        cache.cellLayouts = cellLayouts
        cache.maxWidth = Double(sheetModel.columns.count) * columnSize
        cache.headerLayouts = headerLayouts
    }
    
    override func layoutAttributesForElements(in rect: NSRect) -> [NSCollectionViewLayoutAttributes] {
        var layouts = [NSCollectionViewLayoutAttributes]()
        for cellInfo in cache.cellLayouts.keys {
            let layout = cache.cellLayouts[cellInfo]!
            if rect.intersects(layout.frame) {
                layouts.append(layout)
            }
        }
        for colIdx in cache.headerLayouts.keys {
            let layout = cache.headerLayouts[colIdx]!
            layouts.append(layout)
        }
        return layouts
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> NSCollectionViewLayoutAttributes? {
        return cache.indexToLayout[indexPath]
    }
    
    override func layoutAttributesForSupplementaryView(ofKind elementKind: NSCollectionView.SupplementaryElementKind, at indexPath: IndexPath) -> NSCollectionViewLayoutAttributes? {
        return cache.indexToLayout[indexPath]
    }
//    
//    override func layoutAttributesForDecorationView(ofKind elementKind: NSCollectionView.DecorationElementKind, at indexPath: IndexPath) -> NSCollectionViewLayoutAttributes? {
//        
//    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: NSRect) -> Bool {
        if updateCount < sheetModel.updates {
            updateCount = sheetModel.updates
            return true
        }
        return false
    }
        
//    override func initialLayoutAttributesForAppearingItem(at itemIndexPath: IndexPath) -> NSCollectionViewLayoutAttributes? {
//        
//    }
//    
//    override func finalLayoutAttributesForDisappearingItem(at itemIndexPath: IndexPath) -> NSCollectionViewLayoutAttributes? {
//        
//    }
}
