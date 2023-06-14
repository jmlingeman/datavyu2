//
//  WeakTemporalLayout.swift
//  datavyu
//
//  Created by Jesse Lingeman on 6/13/23.
//

import SwiftUI
import Foundation

struct WeakTemporalLayout: Layout {
    var spacing: CGFloat? = nil
    
    struct CacheData {
        var maxHeight: CGFloat
        var spaces: [CGFloat]
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout CacheData) -> CGSize {
        let idealViewSizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let accumulatedWidths = idealViewSizes.reduce(0) { $0 + $1.width }
        let accumulatedSpaces = cache.spaces.reduce(0) { $0 + $1 }
        
        return CGSize(width: accumulatedSpaces + accumulatedWidths,
                      height: cache.maxHeight)
    }
    
    func getSubviewMap(key: any LayoutValueKey.Type, subviews: Subviews) -> [Int: [LayoutSubview]] {
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
        var pt = CGPoint(x: bounds.minX, y: bounds.minY)
        
        let gapSize = 30.0
        let columnSize = 300.0
        var currentY = 0.0
        var maxHeight = 0.0
        
        let onsetMap = getSubviewMap(key: OnsetKey.self, subviews: subviews)
        let sortedOnsets = onsetMap.keys.sorted()
        
        for onset in sortedOnsets {
            for subview in onsetMap[onset, default: []] {
                pt.y = currentY
                pt.x = Double(subview.columnIdx) * columnSize
                print(pt)
                subview.place(at: pt, proposal: .unspecified)
                maxHeight = max(maxHeight, subview.sizeThatFits(.unspecified).height)
                
            }
            currentY = currentY + maxHeight
            maxHeight = 0
        }
        
        
        
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
        return CacheData(maxHeight: computeMaxHeight(subviews: subviews),
                         spaces: computeSpaces(subviews: subviews))
    }
    
    func updateCache(_ cache: inout CacheData, subviews: Subviews) {
        cache.maxHeight = computeMaxHeight(subviews: subviews)
        cache.spaces = computeSpaces(subviews: subviews)
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
}
