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
    func openInWindow(title: String, appState: AppState, fileModel: FileModel, sender: Any?, frameName: String?) -> NSWindow {
        let controller = NSHostingController(rootView: self)

        if title.starts(with: "Controller") {
            let controllerWin = appState.controllerWindows[fileModel]
            if controllerWin != nil {
                return controllerWin!
            }
        } else if title.starts(with: "Script") {
            let scriptWindows = appState.scriptWindows[fileModel] ?? []
            for sw in scriptWindows {
                if sw.title == title {
                    return sw
                }
            }
        } else if title.starts(with: "Video") {
            let videoWindows = appState.videoWindows[fileModel] ?? []
            for vw in videoWindows {
                if vw.title == title {
                    return vw
                }
            }
        }

        // We havent made this window yet, create it
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
            appState.controllerWindows[fileModel] = win
        } else if title.starts(with: "Script") {
            appState.addScriptWindow(win: win, fileModel: fileModel)
        } else if title.starts(with: "Video") {
            appState.addVideoWindow(win: win, fileModel: fileModel)
        }

        return win
    }

    /// Hide or show the view based on a boolean value.
    ///
    /// Example for visibility:
    ///
    ///     Text("Label")
    ///         .isHidden(true)
    ///
    /// Example for complete removal:
    ///
    ///     Text("Label")
    ///         .isHidden(true, remove: true)
    ///
    /// - Parameters:
    ///   - hidden: Set to `false` to show the view. Set to `true` to hide the view.
    ///   - remove: Boolean value indicating whether or not to remove the view.
    @ViewBuilder func isHidden(_ hidden: Bool, remove: Bool = false) -> some View {
        if hidden {
            if !remove {
                self.hidden()
            }
        } else {
            self
        }
    }

    func closeWindow() {
        NSApplication.shared.keyWindow?.close()
    }
}
