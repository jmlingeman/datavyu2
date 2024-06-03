

import AppKit
import Foundation
import SwiftUI

class OrdinalCollectionViewLayout: TemporalCollectionViewLayout {
    override func prepare() {
        layout = Layouts.ordinal
        print("PREPARING")

        let config = Config()
        let gapSize = config.gapSize
        let columnSize = config.defaultCellWidth
        let headerSize = config.headerSize

        var cellLayouts = [CellInfo: NSCollectionViewLayoutAttributes]()
        var headerLayouts = [Int: NSCollectionViewLayoutAttributes]()

        for (colIdx, column) in sheetModel.visibleColumns.enumerated() {
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

        /* Iterate over all spreadsheet cells and set boundaries using onset and offset maps.
         Keep a local copy of the position maps.  Since each time value gets a range of positions
         (starting from onset map's value and ending at the offset's value), update the local copy of
         the onset map to get positions for cells sharing onsets.
         */
        for colIdx in columnViews.keys {
            var colHeight = config.headerSize
            let colCells = columnViews[colIdx]!
            for curCell in colCells {
                let cellHeight = Double(config.minCellHeight)

                // Set cell boundary
                pts[curCell]?.y = colHeight
                sizes[curCell]?.height = cellHeight

                // Update vars
                colHeight = colHeight + cellHeight
            }

            cache.maxHeight = max(cache.maxHeight, colHeight)
        }

        var i = 0
        var indexToLayout = [IndexPath: NSCollectionViewLayoutAttributes]()
        for colIdx in columnViews.keys {
            let colCells = columnViews[colIdx]!
            for curCell in colCells {
                cellLayouts[curCell]?.frame.origin = pts[curCell]!
                cellLayouts[curCell]?.frame.size = sizes[curCell]!
                cellLayouts[curCell]?.size = sizes[curCell]!

                indexToLayout[cellLayouts[curCell]!.indexPath!] = cellLayouts[curCell]

                i += 1
            }

            indexToLayout[headerLayouts[colIdx]!.indexPath!] = headerLayouts[colIdx]
        }

        cache.indexToLayout = indexToLayout
        cache.cellLayouts = cellLayouts
        cache.maxWidth = Double(sheetModel.visibleColumns.count) * columnSize
        cache.headerLayouts = headerLayouts
    }
}
