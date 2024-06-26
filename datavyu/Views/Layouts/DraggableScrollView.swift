//
//  DraggableScrollView.swift
//  Datavyu2
//
//  Created by Jesse Lingeman on 6/24/24.
//

import AppKit
import Foundation

class DraggableScrollView: NSScrollView {
    override func draggingEntered(_: any NSDraggingInfo) -> NSDragOperation {
        .move
    }
}
