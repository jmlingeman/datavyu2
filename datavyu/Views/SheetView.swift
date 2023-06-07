//
//  SheetView.swift
//  sheettest
//
//  Created by Jesse Lingeman on 6/2/23.
//

import Foundation
import SwiftUI
import TimecodeKit
import WrappingHStack

struct Sheet: View {
    @ObservedObject var sheetDataModel: SheetModel
    @FocusState private var focusedColumn: Bool
    @FocusState var columnInFocus: ColumnModel?
    @State private var offset : CGPoint = .zero
    

    var body: some View {
        GeometryReader { gr in
            ScrollViewReader { proxy in
                // TODO: Have this proxy scroll us to new columns and cells
                
                Text("").id("top") // Anchor for 2d scrollview
                ScrollView([.horizontal, .vertical], showsIndicators: true) {
                    LazyHStack(alignment: .top) {
                        ForEach(sheetDataModel.columns) { column in
                            Column(columnDataModel: column)
                                .focused($columnInFocus, equals: column)
                        }
                    }
                    .frame(minHeight: gr.size.height)
                }.onAppear {
                    proxy.scrollTo("top")
                }
            }
        }
    
    }
}

struct Sheet_Previews: PreviewProvider {
    static var previews: some View {
        let sheetDataModel = SheetModel(sheetName: "TestSheet")
        Sheet(sheetDataModel: sheetDataModel)
    }
}

struct WeakTemporalLayout: Layout {
    @ObservedObject var sheetDataModel: SheetModel
    
    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) -> CGSize {
        // Take whatever space is offered.
        proposal.replacingUnspecifiedDimensions()
    }
    
    /// Places the stack's subviews in a circle.
    /// - Tag: placeSubviewsRadial
    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) {
        // Get the onsets and offsets into dicts of int -> [CellModel]
        
        // Place the cell onsets
        
        // Place the cell offsets
        
        /*
         Can we keep a current cell floor and fill in, moving the floor down?
         
         How to guarantee that cell sizes dont go below minimum required size
         
         Place each onset and offset in order? Keep a running floor. Move floor down as we update the positions of each cell to ensure that the minimum cell height isnt violated
         */
        
        // Place the views within the bounds.
        let radius = min(bounds.size.width, bounds.size.height) / 3.0
        
        // The angle between views depends on the number of views.
        let angle = Angle.degrees(360.0 / Double(subviews.count)).radians
        
        // Read the ranks from each view, and find the appropriate offset.
        // This only has an effect for the specific case of three views with
        // nonuniform rank values. Otherwise, the offset is zero, and it has
        // no effect on the placement.
        let ranks = subviews.map { subview in
            subview[Rank.self]
        }
        let offset = getOffset(ranks)
        
        for (index, subview) in subviews.enumerated() {
            if let sv = subview as? Cell {
                // Operate on cells -- columns should already be placed
                
            }
            // Find a vector with an appropriate size and rotation.
            var point = CGPoint(x: 0, y: -radius)
                .applying(CGAffineTransform(
                    rotationAngle: angle * Double(index) + offset))
            
            // Shift the vector to the middle of the region.
            point.x += bounds.midX
            point.y += bounds.midY
            
            // Place the subview.
            subview.place(at: point, anchor: .center, proposal: .unspecified)
        }
    }
}


extension WeakTemporalLayout {
    /// Finds the angular offset that arranges the views in rank order.
    ///
    /// This method produces an offset that tells a radial layout how much
    /// to rotate all of its subviews so that they display in order, from
    /// top to bottom, according to their ranks. The method only has meaning
    /// for exactly three laid-out views, initially positioned with the first
    /// view at the top, the second at the lower right, and the third in the
    /// lower left of the radial layout.
    ///
    /// - Parameter ranks: The rank values for the three subviews. Provide
    ///   exactly three ranks.
    ///
    /// - Returns: An angle in radians. The method returns zero if you provide
    ///   anything other than three ranks, or if the ranks are all equal,
    ///   representing a three-way tie.
    private func getOffset(_ ranks: [Int]) -> Double {
        guard ranks.count == 3,
              !ranks.allSatisfy({ $0 == ranks.first }) else { return 0.0 }
        
        // Get the offset as a fraction of a third of a circle.
        // Put the leader at the top of the circle, and then adjust by
        // a residual amount depending on what the other two are doing.
        var fraction: Double
        if ranks[0] == 1 {
            fraction = residual(rank1: ranks[1], rank2: ranks[2])
        } else if ranks[1] == 1 {
            fraction = -1 + residual(rank1: ranks[2], rank2: ranks[0])
        } else {
            fraction = 1 + residual(rank1: ranks[0], rank2: ranks[1])
        }
        
        // Convert the fraction to an angle in radians.
        return fraction * 2.0 * Double.pi / 3.0
    }
    
    /// Gets the residual fraction based on what the other two ranks are doing.
    private func residual(rank1: Int, rank2: Int) -> Double {
        if rank1 == 1 {
            return -0.5
        } else if rank2 == 1 {
            return 0.5
        } else if rank1 < rank2 {
            return -0.25
        } else if rank1 > rank2 {
            return 0.25
        } else {
            return 0
        }
    }
}

/// A key that the layout uses to read the rank for a subview.
private struct Rank: LayoutValueKey {
    static let defaultValue: Int = 1
}

extension View {
    /// Sets the rank layout value on a view.
    func rank(_ value: Int) -> some View {
        layoutValue(key: Rank.self, value: value)
    }
}
