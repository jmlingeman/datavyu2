//
//  DraggableScrollView.swift
//  Datavyu2
//
//  Created by Jesse Lingeman on 6/24/24.
//

import AppKit
import Foundation

class DraggableScrollView: NSScrollView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        registerForDraggedTypes([.string])
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draggingEntered(_: any NSDraggingInfo) -> NSDragOperation {
        .move
    }

    func performDraggingOperation(_: any NSDraggingInfo) -> Bool {
        true
    }
}
