//
//  AppState.swift
//  datavyu
//
//  Created by Jesse Lingeman on 5/27/24.
//

import Foundation
import AppKit

public class AppState: ObservableObject {
    @Published var fileController: FileControllerModel?

    @Published var controllerWindows: [FileModel: NSWindow] = [:]
    @Published var videoWindows: [FileModel: [NSWindow]] = [:]
    @Published var scriptWindows: [FileModel: [NSWindow]] = [:]
    @Published var layout: LayoutChoice = LayoutChoice()
    @Published var config: Config = Config()
    
    
    func setControllerWindow(win: NSWindow) {
        controllerWindows[fileController!.activeFileModel] = win
    }
    
    func addVideoWindow(win: NSWindow) {
        videoWindows[fileController!.activeFileModel, default: []].append(win)
    }
    
    func addScriptWindow(win: NSWindow) {
        scriptWindows[fileController!.activeFileModel, default: []].append(win)
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
    
    func showWindows(fileModel: FileModel) {
        controllerWindows[fileModel]?.orderFront(self)
        for vw in videoWindows[fileModel] ?? [] {
            vw.orderFront(self)
        }
        for sw in scriptWindows[fileModel] ?? [] {
            sw.orderFront(self)
        }
    }
}
