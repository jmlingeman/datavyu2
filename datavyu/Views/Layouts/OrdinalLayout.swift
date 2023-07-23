//
//  WeakTemporalLayout.swift
//  datavyu
//
//  Created by Jesse Lingeman on 6/13/23.
//

import SwiftUI
import Foundation

struct OrdinalLayout: Layout {
    var sheetModel: ObservedObject<SheetModel>.Wrapper
    var spacing: CGFloat? = nil
    
    struct CacheData {
        var maxHeight: CGFloat
        var maxWidth: CGFloat
        var spaces: [CGFloat]
    }
    
    func closestMatch(values: [Int], inputValue: Int) -> Int? {
        return (values.reduce(values[0]) { abs($0-inputValue) < abs($1-inputValue) ? $0 : $1 })
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout CacheData) -> CGSize {
        return CGSize(width: cache.maxWidth,
                      height: cache.maxHeight)
    }
    
    func getSubviewMap(key: any LayoutValueKey.Type, subviews: [LayoutSubview]) -> [Int: [LayoutSubview]] {
        var subviewMap: [Int: [LayoutSubview]] = [:]
        for subview in subviews {
            let onset = subview.onset
            var subviewList = subviewMap[onset, default: []]
            subviewList.append(subview)
            subviewMap.updateValue(subviewList, forKey: onset)
        }
        
        return subviewMap
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout CacheData) {
        /*
         
         Get the onsets and offsets for each cell, start at the min and go in order.
         - Order cells by onset in onset -> subview map
         - Order cells by offset in offset -> subview map
         - Have an array of onsets and offsets, ordered, to look over.
         
         - For cells with onset, set their Y position (and X based on column).
         - Get min height of cells at that onset, move min pointer down below that
         - If a cell's offset is at that location, extend that subview's frame
         
         */
        //        var pt = CGPoint(x: bounds.minX, y: bounds.minY)
        
        
        let config = Config()
        let gapSize = config.gapSize
        let columnSize = config.defaultCellWidth
        let headerSize = config.headerSize
        
        
        
        let titleSubviews = subviews.filter({subview in
            subview[ObjectType.self] == "title"
        }).sorted(by: {a, b in
            a[ColumnKey.self] < b[ColumnKey.self]
        })
        
        let cellSubviews = subviews.filter({subview in
            subview[ObjectType.self] == "cell"
        })
        
        /*
         Idea: Loop through storing proposed positions
         Loop through again to fix the heights based on placed onsets/offsets
         */
        
        // Bookkeeping Hashmaps
        var sizes: [String: CGSize] = [:]
        var pts: [String: CGPoint] = [:]
        var heightMap: [Int: Double] = [:]
        var onsetToPos: [Int: Double] = [:]
        var offsetToPos: [Int: Double] = [:]
        
        
        // Assign defaults
        for subview in cellSubviews {
            sizes[subview.cellIdx] = CGSize(width: columnSize, height: 0)
            pts[subview.cellIdx] = CGPoint(x: Int(columnSize) * subview.columnIdx, y: 0)
        }
        var times = Set<Int>()
        
        var columnViews: [Int: [LayoutSubview]] = [:]
        for subview in cellSubviews {
            columnViews[subview.columnIdx, default: []].append(subview)
        }
        for colIdx in columnViews.keys {
            columnViews[colIdx] = columnViews[colIdx]?.sorted(by: {
                if $0.onset == $1.onset {
                    if $0.offset == $1.offset {
                        return $0.cellIdx < $1.cellIdx
                    }
                    return $0.offset < $1.offset
                }
                return $0.onset < $1.onset
            })
        }
        
        for titleView in titleSubviews {
            let pt = CGPoint(x: columnSize * Double(titleView[ColumnKey.self]), y: 0)
            titleView.place(at: pt, proposal: .unspecified)
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
            var colHeight = config.headerSize
            let colCells = columnViews[colIdx]!
            for (idx, curCell) in colCells.enumerated() {
                
                let onset = curCell.onset
                let offset = curCell.offset
                let cellTopY = colHeight
                
                var cellHeight = curCell.sizeThatFits(.unspecified).height

                
                // Set cell boundary
                pts[curCell.cellIdx]?.y = cellTopY
                sizes[curCell.cellIdx]?.height = cellHeight
                
                // Update vars
                colHeight = cellTopY + cellHeight;
            }
            
            cache.maxHeight = max(cache.maxHeight, colHeight)
        }
        
        
        for colIdx in columnViews.keys {
            let colCells = columnViews[colIdx]!
            for curCell in colCells {
                let mapHeight = offsetToPos[curCell.offset, default: -1] - pts[curCell.cellIdx]!.y
                if sizes[curCell.cellIdx]!.height < mapHeight {
//                    sizes[curCell.cellIdx]?.height = mapHeight
                }
                curCell.place(at: pts[curCell.cellIdx]!, proposal: ProposedViewSize(sizes[curCell.cellIdx]!))
            }
        }
        
        cache.maxWidth = Double(sheetModel.columns.count) * columnSize
    }
    
    
    func computeSpaces(subviews: LayoutSubviews) -> [CGFloat] {
        if let spacing {
            return Array<CGFloat>(repeating: spacing, count: subviews.count - 1)
        } else {
            return subviews.indices.map { idx in
                guard idx < subviews.count - 1 else { return CGFloat(0) }
                
                // Can use this to place the cells at the correct location
                return subviews[idx].spacing.distance(to: subviews[idx+1].spacing, along: .horizontal)
            }
        }
    }
    
    func computeMaxHeight(subviews: LayoutSubviews) -> CGFloat {
        return subviews.map { $0.sizeThatFits(.unspecified) }.reduce(0) { max($0, $1.height) }
    }
    
    func makeCache(subviews: Subviews) -> CacheData {
        return CacheData(maxHeight: computeMaxHeight(subviews: subviews), maxWidth: 600,
                         spaces: computeSpaces(subviews: subviews))
    }
    
    func updateCache(_ cache: inout CacheData, subviews: Subviews) {
        //        cache.maxHeight = computeMaxHeight(subviews: subviews)
        //        cache.spaces = computeSpaces(subviews: subviews)
    }
}
