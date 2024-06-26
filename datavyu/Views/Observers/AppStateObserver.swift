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

    init(object: AppState, cellItem: CellViewUIKit) {
        appState = object
        self.cellItem = cellItem
        super.init()

        observation = observe(
            \.appState.playbackTime,
            options: [.old, .new]
        ) { _, change in
            print("myDate changed from: \(change.oldValue!), updated to: \(change.newValue!)")
            let playbackTimeMs = secondsToMillis(secs: self.appState.playbackTime)
            if self.appState.highlightMode {
                if playbackTimeMs >= self.cellItem.cell.onset, playbackTimeMs <= self.cellItem.cell.offset {
                    cellItem.setHighlightActive()
                } else if playbackTimeMs >= self.cellItem.cell.offset {
                    cellItem.setHighlightPassed()
                }
            }
        }
    }
}
