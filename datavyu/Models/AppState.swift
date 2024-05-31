//
//  AppState.swift
//  datavyu
//
//  Created by Jesse Lingeman on 5/27/24.
//

import Foundation
import AppKit

public class AppState: ObservableObject {
    @Published var controllerWindow: NSWindow?
    @Published var videoWindows: [NSWindow] = []
    @Published var scriptWindows: [NSWindow] = []
    @Published var layout: LayoutChoice = LayoutChoice()
}
