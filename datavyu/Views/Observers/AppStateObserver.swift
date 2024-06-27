//
//  AppStateObserver.swift
//  Datavyu2
//
//  Created by Jesse Lingeman on 6/25/24.
//

import Foundation

class AppStateObserver: NSObject {
    @objc var appState: AppState
    var cellItem: CellViewUIKit
    var observation: NSKeyValueObservation?
    var isSet = false

    init(object: AppState, cellItem: CellViewUIKit) {
        appState = object
        self.cellItem = cellItem
        super.init()

        observation = observe(
            \.appState.playbackTime,
            options: [.old, .new]
        ) { _, _ in
            let playbackTimeMs = secondsToMillis(secs: self.appState.playbackTime)
            if self.appState.highlightMode {
                if !self.isSet, playbackTimeMs >= self.cellItem.cell.onset, playbackTimeMs <= self.cellItem.cell.offset {
                    cellItem.setHighlightActive()
                    self.isSet = true
                    if self.appState.focusMode {
                        cellItem.focusArgument(IndexPath(item: 0, section: 0))
                    }
                } else if playbackTimeMs >= self.cellItem.cell.offset {
                    self.isSet = false
                    cellItem.setHighlightPassed()
                }
            }
        }
    }
}
