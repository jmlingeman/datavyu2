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
    func openInWindow(title: String, appState: AppState, sender: Any?, frameName: String?) -> NSWindow {
        let controller = NSHostingController(rootView: self)
        let win = NSWindow(contentViewController: controller)
        win.contentViewController = controller
        win.title = title
        win.makeKeyAndOrderFront(sender)
        win.tabbingMode = .disallowed
        win.identifier = NSUserInterfaceItemIdentifier(title)
        win.isReleasedWhenClosed = false

        win.setFrame(NSRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 500, height: 500)), display: true)

        if frameName != nil {
            let _ = win.setFrameUsingName(frameName!)
            win.setFrameAutosaveName(frameName!)
        }
        
        if title.starts(with: "Controller") {
            appState.controllerWindow = win
        } else if title.starts(with: "Script") {
            appState.scriptWindows.append(win)
        } else if title.starts(with: "Video") {
            appState.videoWindows.append(win)
        }

        return win
    }

    func closeWindow() {
        NSApplication.shared.keyWindow?.close()
    }
}
