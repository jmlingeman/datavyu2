//
//  AppState.swift
//  datavyu
//
//  Created by Jesse Lingeman on 5/27/24.
//

import AppKit
import Foundation

public class AppState: ObservableObject {
    @Published var fileController: FileControllerModel?

    @Published var controllerWindows: [FileModel: NSWindow] = [:]
    @Published var videoWindows: [FileModel: [NSWindow]] = [:]
    @Published var scriptWindows: [FileModel: [NSWindow]] = [:]
    @Published var layout: LayoutChoice = .init()
    @Published var config: Config = .init()

    func setControllerWindow(win: NSWindow) {
        controllerWindows[fileController!.activeFileModel] = win
    }

    func addVideoWindow(win: NSWindow) {
        videoWindows[fileController!.activeFileModel, default: []].append(win)
    }

    func addScriptWindow(win: NSWindow) {
        scriptWindows[fileController!.activeFileModel, default: []].append(win)
    }

    func removeVideo(fileModel: FileModel, videoTitle: String) {
        hideWindow(fileModel: fileModel, title: videoTitle)
        videoWindows[fileModel]?.removeAll { win in
            win.title == videoTitle
        }
    }

    func hideWindows(fileModel: FileModel) {
        controllerWindows[fileModel]?.orderOut(self)
        for vw in videoWindows[fileModel] ?? [] {
            vw.orderOut(self)
        }
        for sw in scriptWindows[fileModel] ?? [] {
            sw.orderOut(self)
        }
    }

    func hideWindow(fileModel: FileModel, title: String) {
        for vw in videoWindows[fileModel] ?? [] {
            if title == vw.title {
                vw.orderOut(self)
            }
        }
        for sw in scriptWindows[fileModel] ?? [] {
            if title == sw.title {
                sw.orderOut(self)
            }
        }
    }

    func showWindows(fileModel: FileModel) {
        controllerWindows[fileModel]?.orderFront(self)
        for vw in videoWindows[fileModel] ?? [] {
            vw.orderFront(self)
        }
        for sw in scriptWindows[fileModel] ?? [] {
            sw.orderFront(self)
        }
    }

    func showWindow(fileModel: FileModel, title: String) {
        for vw in videoWindows[fileModel] ?? [] {
            if title == vw.title {
                vw.orderFront(self)
            }
        }
        for sw in scriptWindows[fileModel] ?? [] {
            if title == sw.title {
                sw.orderFront(self)
            }
        }
    }
}
