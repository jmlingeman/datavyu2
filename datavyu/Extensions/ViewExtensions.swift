//
//  ViewExtensions.swift
//  datavyu
//
//  Created by Jesse Lingeman on 5/13/24.
//

import Foundation
import SwiftUI


extension View {
    @discardableResult
    func openInWindow(title: String, sender: Any?, frameName: String?) -> NSWindow {
        let controller = NSHostingController(rootView: self)
        let win = NSWindow(contentViewController: controller)
        win.contentViewController = controller
        win.title = title
        win.makeKeyAndOrderFront(sender)
        win.tabbingMode = .disallowed
        
        win.setFrame(NSRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 500, height: 500)), display: true)
        
        if frameName != nil {
            let _ = win.setFrameUsingName(frameName!)
            win.setFrameAutosaveName(frameName!)
        }
        
        return win
    }
    
    func closeWindow() {
        NSApplication.shared.keyWindow?.close()
    }
}
