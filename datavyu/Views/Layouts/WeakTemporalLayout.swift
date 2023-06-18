//
//  WeakTemporalLayout.swift
//  datavyu
//
//  Created by Jesse Lingeman on 6/13/23.
//

import SwiftUI
import Foundation

struct WeakTemporalLayout: Layout {
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
        
        
        let gapSize = 30.0
        let columnSize = 300.0
        let headerSize = 50.0
        var currentOnsetY = Array(repeating: headerSize, count: sheetModel.columns.count)
        var currentOffsetY = Array(repeating: headerSize, count: sheetModel.columns.count)
        var currentOnset = Array(repeating: 0, count: sheetModel.columns.count)
        var currentOffset = Array(repeating: 0, count: sheetModel.columns.count)
        
        
        
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
        var sizes: [String: CGSize] = [:]
        var pts: [String: CGPoint] = [:]
        for subview in cellSubviews {
            sizes[subview.cellIdx] = CGSize(width: columnSize, height: 0)
            pts[subview.cellIdx] = CGPoint(x: Int(columnSize) * subview.columnIdx, y: 0)
        }
        var times = Set<Int>()
        
        let onsetMap = getSubviewMap(key: OnsetKey.self, subviews: cellSubviews)
        let offsetMap = getSubviewMap(key: OffsetKey.self, subviews: cellSubviews)
        let columnMap = getSubviewMap(key: ColumnKey.self, subviews: cellSubviews)
        let sortedOnsets = onsetMap.keys.sorted()
        let sortedOffsets = offsetMap.keys.sorted()
        
        // Map describing the Y offsets for each time
        var positionMap: [Int: Double] = [:]
        
        for subview in cellSubviews{
            sizes[subview.cellIdx] = CGSize()
        }
        
        var columnViews: [Int: [LayoutSubview]] = [:]
        for subview in cellSubviews {
            columnViews[subview.columnIdx, default: []].append(subview)
        }
        for colIdx in columnViews.keys {
            columnViews[colIdx] = columnViews[colIdx]?.sorted(by: {$0.onset < $1.onset})
        }
        
        for titleView in titleSubviews {
            let pt = CGPoint(x: columnSize * Double(titleView[ColumnKey.self]), y: 0)
            titleView.place(at: pt, proposal: .unspecified)
        }
        
        /* Go through each column and assign "height" values to onset times.
         This will determine how much space to allocate between onset times.
         For each column, create an intermediate map and then merge with the
         actual map using maximum values.  This is required since a column can have
         multiple cells with the same onset.
         Also accumulate all unique times.
         */
        
        var heightMap: [Int: Double] = [:]
        for colIdx in columnViews.keys {
            var intermediateMap: [Int: Double] = [:]
            for cell in columnViews[colIdx]! {
                let height = cell.sizeThatFits(.unspecified).height
                let onset = cell.onset
                intermediateMap[onset] = intermediateMap[onset, default: 0] + height
                times.insert(cell.onset)
                if cell.offset > cell.onset {
                    times.insert(cell.offset)
                }
            }
            for onset in intermediateMap.keys {
                heightMap[onset] = max(heightMap[onset, default: 0], intermediateMap[onset]!)
            }
        }
        
        var pos = 0.0
        var onsetToPos: [Int: Double] = [:]
        for time in times {
            onsetToPos[time] = pos
            pos += heightMap[time, default: 0]
            pos += gapSize
        }
        
        /* Iterate over all spreadsheet cells and set boundaries using onset and offset maps.
         Keep a local copy of the position maps.  Since each time value gets a range of positions
         (starting from onset map's value and ending at the offset's value), update the local copy of
         the onset map to get positions for cells sharing onsets.
         */
        var offsetToPos: [Int: Double] = [:]
        for colIdx in columnViews.keys {
            var colHeight = 0.0
            var onsetMapLocal: [Int: Double] = onsetToPos
            var prevCell: LayoutSubview?
            var colCells = columnViews[colIdx]!
            for (idx, curCell) in colCells.enumerated() {
                var nextCell: LayoutSubview?
                if idx+1 < colCells.count {
                    nextCell = colCells[idx+1]
                }
                
                let onset = curCell.onset
                let offset = curCell.offset
                let cellTopY = onsetMapLocal[onset]!
                
                var cellHeight = 0.0
                if onset > offset {
                    // TODO: Set overlap border here
                    cellHeight = curCell.sizeThatFits(.unspecified).height
                } else if nextCell != nil && onset == nextCell!.onset {
                    if onset != offset || offset == nextCell!.offset {
                        // TODO: Set overlap border here
                    }
                    cellHeight = curCell.sizeThatFits(.unspecified).height
                } else if nextCell != nil && offset >= nextCell!.onset {
                    // TODO: Set overlap border here
                    cellHeight = onsetMapLocal[nextCell!.onset]! - cellTopY;
                } else {
                    cellHeight = offsetToPos[offset, default: onsetToPos[offset]!] - cellTopY;
                }
                
                if prevCell != nil && onset - prevCell!.offset == 1 {
                    sizes[prevCell!.cellIdx]!.height =  cellTopY - sizes[prevCell!.cellIdx]!.height
                    offsetToPos[offset] = max(offsetToPos[offset] ?? 0, cellTopY)
                }
                
                // fix for edge cases...maybe investigate later
                cellHeight = max(cellHeight, curCell.sizeThatFits(.unspecified).height);
                // Set cell boundary
                pts[curCell.cellIdx]?.y = cellTopY
                sizes[curCell.cellIdx]?.height = cellHeight
                
                // Update local onset map
                onsetMapLocal[onset] = onsetMapLocal[onset]! + cellHeight
                
                // Only do if we're not setting overlap
                offsetToPos[offset] = max(offsetToPos[offset, default: cellTopY + cellHeight], cellTopY + cellHeight)
                
                // Update offset map
//                if(!curCell.getOverlapBorder()) {
//                    int adjOff = cellTopY + cellHeight;
//                    offsetMap.compute(offset, (k, v) -> (v == null) ? adjOff : Math.max(v, adjOff));
//                }
                
                // Update vars
                colHeight = cellTopY + cellHeight;
                prevCell = curCell;
            }
            
            cache.maxHeight = max(cache.maxHeight, colHeight)
        }

        
        for colIdx in columnViews.keys {
            let colCells = columnViews[colIdx]!
            for curCell in colCells {
                let mapHeight = offsetToPos[curCell.offset, default: -1] - pts[curCell.cellIdx]!.y
                if sizes[curCell.cellIdx]!.height < mapHeight {
                    sizes[curCell.cellIdx]?.height = mapHeight
                }
                curCell.place(at: pts[curCell.cellIdx]!, proposal: ProposedViewSize(sizes[curCell.cellIdx]!))
            }
        }
        
        cache.maxHeight = currentOffsetY.max() ?? 300
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

struct OnsetKey: LayoutValueKey {
    static var defaultValue: Int = 0
}

struct OffsetKey: LayoutValueKey {
    static var defaultValue: Int = 0
}

struct ColumnKey: LayoutValueKey {
    static var defaultValue: Int = 0
}

struct ObjectType: LayoutValueKey {
    static var defaultValue: String = ""
}

struct CellIdx: LayoutValueKey {
    static var defaultValue: String = ""
}

struct Overlap: LayoutValueKey {
    static var defaultValue: Bool = false
}

extension LayoutSubview {
    var onset: Int {
        self[OnsetKey.self]
    }
    
    var offset: Int {
        self[OffsetKey.self]
    }
    
    var columnIdx: Int {
        self[ColumnKey.self]
    }
    
    var objectType: String {
        self[ObjectType.self]
    }
    
    var cellIdx: String {
        self[CellIdx.self]
    }
    
    var overlap: Bool {
        self[Overlap.self]
    }
}

extension View {
    func setOnset(_ onset: Binding<Int>) -> some View {
        layoutValue(key: OnsetKey.self, value: onset.wrappedValue)
    }
    
    func setOffset(_ offset: Binding<Int>) -> some View {
        layoutValue(key: OffsetKey.self, value: offset.wrappedValue)
    }
    
    func setColumnIdx(_ colIdx: Int) -> some View {
        layoutValue(key: ColumnKey.self, value: colIdx)
    }
    
    func setObjectType(_ objectType: String) -> some View {
        layoutValue(key: ObjectType.self, value: objectType)
    }
    
    func setCellIdx(_ cellIdx: String) -> some View {
        layoutValue(key: CellIdx.self, value: cellIdx)
    }
    
    func setOverlap(_ overlap: Bool) -> some View {
        layoutValue(key: Overlap.self, value: overlap)
    }
    
}
