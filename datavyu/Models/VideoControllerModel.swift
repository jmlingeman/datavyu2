//
//  VideoControllerModel.swift
//  Datavyu2
//
//  Created by Jesse Lingeman on 6/4/24.
//

import Foundation

class VideoController: ObservableObject {
    var fileModel: FileModel
    var currentShuttleSpeedIdx: Int = 0

    init(fileModel: FileModel) {
        self.fileModel = fileModel
        currentShuttleSpeedIdx = Config.shuttleSpeeds.firstIndex(of: 0)!
    }

    func changeShuttleSpeed(step: Int) {
        if currentShuttleSpeedIdx + step < Config.shuttleSpeeds.count, currentShuttleSpeedIdx + step >= 0 {
            currentShuttleSpeedIdx += step
        }
        for video in fileModel.videoModels {
            video.player.rate = Config.shuttleSpeeds[currentShuttleSpeedIdx]
        }
    }

    func resetShuttleSpeed() {
        currentShuttleSpeedIdx = Config.shuttleSpeeds.firstIndex(of: 0)!
    }

    func play() {
        if currentShuttleSpeedIdx == Config.shuttleSpeeds.firstIndex(of: 0)! {
            currentShuttleSpeedIdx = Config.shuttleSpeeds.firstIndex(of: 1)!
        }
        for videoModel in fileModel.videoModels {
            videoModel.play()
        }
    }

    func stepFrame(reverse: Bool = false) {
        var highestFps: Float = -1.0
        var highestFpsVideo: VideoModel?

        for videoModel in fileModel.videoModels {
            let fps = videoModel.getFps()
            if fps > highestFps {
                highestFps = fps
                highestFpsVideo = videoModel
            }
        }

        if !reverse {
            highestFpsVideo?.nextFrame()
        } else {
            highestFpsVideo?.prevFrame()
        }

        for videoModel in fileModel.videoModels {
            if videoModel == highestFpsVideo {
                continue
            }

            videoModel.seek(to: highestFpsVideo!.currentTime)
        }
    }

    func nextFrame() {
        stepFrame()
    }

    func prevFrame() {
        stepFrame(reverse: true)
    }

    func jump(jumpValue: String) {
        fileModel.seekAllVideos(to: fileModel.currentTime() - Double(timestringToSecondsDouble(timestring: jumpValue)))
    }

    func findOnset() {
        if fileModel.sheetModel.focusController.focusedCell != nil {
            find(value: millisToSeconds(millis: fileModel.sheetModel.focusController.focusedCell!.onset))
        }
    }

    func findOffset() {
        if fileModel.sheetModel.focusController.focusedCell != nil {
            find(value: millisToSeconds(millis: fileModel.sheetModel.focusController.focusedCell!.offset))
        }
    }

    func getOnset() -> Int {
        if fileModel.sheetModel.focusController.focusedCell != nil {
            return fileModel.sheetModel.focusController.focusedCell!.onset
        }
        return 0
    }

    func getOffset() -> Int {
        if fileModel.sheetModel.focusController.focusedCell != nil {
            return fileModel.sheetModel.focusController.focusedCell!.offset
        }
        return 0
    }

    func find(value: Double) {
        fileModel.seekAllVideos(to: value)
    }

    func shuttleStepUp() {
        changeShuttleSpeed(step: 1)
    }

    func shuttleStepDown() {
        changeShuttleSpeed(step: -1)
    }

    func stop() {
        for videoModel in fileModel.videoModels {
            videoModel.stop()
        }
        fileModel.syncVideos()
        resetShuttleSpeed()
    }

    func pause() {
        for videoModel in fileModel.videoModels {
            videoModel.stop()
        }
        fileModel.syncVideos()
    }

    func addCell() {
        let model = fileModel.sheetModel.findFocusedColumn()

        let cell = model?.addCell()
        fileModel.sheetModel.focusController.setFocusedCell(cell: cell)
        if cell != nil {
            cell?.setOnset(onset: fileModel.primaryVideo?.currentTime ?? 0)
        }
        fileModel.sheetModel.updates += 1 // Force sheetmodel updates of nested objects
    }

    func setOnset() {
        fileModel.sheetModel.focusController.focusedCell?.setOnset(onset: fileModel.currentTime())
    }

    func setOffset() {
        fileModel.sheetModel.focusController.focusedCell?.setOffset(offset: fileModel.currentTime())
    }

    func setOffsetAndAddNewCell() {
        fileModel.sheetModel.focusController.focusedCell?.setOffset(offset: fileModel.currentTime())
        let cell = fileModel.sheetModel.focusController.focusedCell?.column?.addCell(onset: secondsToMillis(secs: fileModel.currentTime()) + 1)
        fileModel.sheetModel.focusController.setFocusedCell(cell: cell)

        fileModel.sheetModel.updateSheet()
    }
}
