//
//  VideoControllerModel.swift
//  Datavyu2
//
//  Created by Jesse Lingeman on 6/4/24.
//

import Foundation

class VideoController: ObservableObject {
    var fileModel: FileModel

    init(fileModel: FileModel) {
        self.fileModel = fileModel
    }

    func play() {
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
        if fileModel.sheetModel.selectedCell != nil {
            find(value: millisToSeconds(millis: fileModel.sheetModel.selectedCell!.onset))
        }
    }

    func findOffset() {
        if fileModel.sheetModel.selectedCell != nil {
            find(value: millisToSeconds(millis: fileModel.sheetModel.selectedCell!.offset))
        }
    }

    func getOnset() -> Int {
        if fileModel.sheetModel.selectedCell != nil {
            return fileModel.sheetModel.selectedCell!.onset
        }
        return 0
    }

    func getOffset() -> Int {
        if fileModel.sheetModel.selectedCell != nil {
            return fileModel.sheetModel.selectedCell!.offset
        }
        return 0
    }

    func find(value: Double) {
        fileModel.seekAllVideos(to: value)
    }

    func shuttleStepUp() {
        fileModel.changeShuttleSpeed(step: 1)
    }

    func shuttleStepDown() {
        fileModel.changeShuttleSpeed(step: -1)
    }

    func stop() {
        for videoModel in fileModel.videoModels {
            videoModel.stop()
        }
        fileModel.syncVideos()
        fileModel.resetShuttleSpeed()
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
        fileModel.sheetModel.setSelectedCell(selectedCell: cell)
        if cell != nil {
            cell?.setOnset(onset: fileModel.primaryVideo?.currentTime ?? 0)
        }
        fileModel.sheetModel.updates += 1 // Force sheetmodel updates of nested objects
    }

    func setOnset() {
        fileModel.sheetModel.selectedCell?.setOnset(onset: fileModel.currentTime())
    }

    func setOffset() {
        fileModel.sheetModel.selectedCell?.setOffset(offset: fileModel.currentTime())
    }

    func setOffsetAndAddNewCell() {
        fileModel.sheetModel.selectedCell?.setOffset(offset: fileModel.currentTime())
        let cell = fileModel.sheetModel.selectedCell?.column?.addCell(onset: secondsToMillis(secs: fileModel.currentTime()) + 1)
        fileModel.sheetModel.setSelectedCell(selectedCell: cell)

        fileModel.sheetModel.updateSheet()
    }
}
