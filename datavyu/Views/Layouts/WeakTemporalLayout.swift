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
        
        let titleSubviews = subviews.filter({subview in
            subview[ObjectType.self] == "title"
        }).sorted(by: {a, b in
            a[ColumnKey.self] < b[ColumnKey.self]
        })
        
        let cellSubviews = subviews.filter({subview in
            subview[ObjectType.self] == "cell"
        })
        
        let onsetMap = getSubviewMap(key: OnsetKey.self, subviews: cellSubviews)
        let offsetMap = getSubviewMap(key: OffsetKey.self, subviews: cellSubviews)
        let columnMap = getSubviewMap(key: ColumnKey.self, subviews: cellSubviews)
        let sortedOnsets = onsetMap.keys.sorted()
        
        for titleView in titleSubviews {
            let pt = CGPoint(x: columnSize * Double(titleView[ColumnKey.self]), y: 0)
            titleView.place(at: pt, proposal: .unspecified)
        }
        
        for onset in sortedOnsets {
            let localSubviews = onsetMap[onset, default: []]
            var prevOffset = localSubviews.map({x in x.offset}).sorted().min() ?? 0
                        
            for (idx, subview) in localSubviews.sorted(by: {$0.offset < $1.offset}).enumerated() {
                
                if subview.offset > prevOffset {
                    currentOffsetY[subview.columnIdx] += gapSize
                    prevOffset = subview.offset
                }
                let pt = CGPoint(x: Double(subview.columnIdx) * columnSize, y: currentOnsetY[subview.columnIdx])
                let cellHeight = subview.sizeThatFits(.unspecified).height
                let offsetAdjustment = currentOffsetY[subview.columnIdx] - currentOnsetY[subview.columnIdx]
                print(idx, "sizethatfits", cellHeight, cellHeight + offsetAdjustment, "current onset y", currentOnsetY[subview.columnIdx], offsetAdjustment)

                print(pt)
                subview.place(at: pt, proposal:
                                ProposedViewSize(CGSize(
                                    width: columnSize,
                                    height: cellHeight + offsetAdjustment
                                    )
                                )
                )
                
                currentOffsetY[subview.columnIdx] = currentOffsetY[subview.columnIdx] + cellHeight
                currentOnsetY[subview.columnIdx] = currentOnsetY[subview.columnIdx] + cellHeight
            }
            
            // Since we're moving to the next onset, mark the new bottoms
            let maxOnsetY = currentOnsetY.max()!
            let maxOffsetY = currentOffsetY.max()!
            for idx in currentOnsetY.indices {
                currentOnsetY[idx] = maxOnsetY
                currentOffsetY[idx] = maxOffsetY
            }
        }
        cache.maxHeight = currentOffsetY.max() ?? 300
        cache.maxWidth = Double(sheetModel.columns.count) * columnSize

        
        
        
//        for idx in subviews.indices {
//            subviews[idx].place(at: pt, anchor: .topLeading, proposal: .unspecified)
//
//            if idx < subviews.count - 1 {
//                pt.x += subviews[idx].sizeThatFits(.unspecified).width + cache.spaces[idx]
//            }
//        }
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
}
