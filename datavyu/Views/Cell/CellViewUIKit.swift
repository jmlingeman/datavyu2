//
//  CellViewUIKit.swift
//  datavyu
//
//  Created by Jesse Lingeman on 1/30/24.
//

import AppKit
import Foundation
import SwiftUI

enum CellHighlightState {
    case active
    case passed
    case off
}

class CellViewUIKit: NSCollectionViewItem {
    static let identifier: String = "CellViewUIKit"
    static let dummyCell = CellModel(column: ColumnModel(sheetModel: SheetModel(sheetName: "temp"), columnName: "temp"))

    @IBOutlet var onset: CellTimeTextField!
    @IBOutlet var offset: CellTimeTextField!
    @IBOutlet var ordinal: NSTextField!
//    @IBOutlet var argumentsCollectionView: NSCollectionView!
    @IBOutlet var cellTextField: CellTextField!

    var onsetCoordinator: OnsetCoordinator?
    var offsetCoordinator: OffsetCoordinator?

    var argumentSizes: [IndexPath: NSSize]

    var parentView: SheetCollectionAppKitView?

    var lastEditedField: LastEditedField = .none

    var appState: AppState?

    var highlightObserver: AppStateObserver?
    var highlightStatus: CellHighlightState = .off

    @ObservedObject var cell: CellModel

    override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?) {
        cell = CellViewUIKit.dummyCell
        ordinal = NSTextField()
        onset = CellTimeTextField()
        offset = CellTimeTextField()
        cellTextField = CellTextField()

        argumentSizes = [IndexPath: NSSize]()

        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

        ValueTransformer.setValueTransformer(TimestampTransformer(), forName: .classNameTransformerName)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func numArguments() -> Int {
        cell.arguments.count
    }

    func isLastArgument() -> Bool {
//        let selectedIndexPaths = argumentsCollectionView?.selectionIndexPaths
//        return selectedIndexPaths?.first?.item == cell.arguments.count - 1
        false
    }

    func configureCell(_ cell: CellModel, parentView: SheetCollectionAppKitView?, appState: AppState?) {
//        Logger.info("CONFIGURING CELL")

        self.cell = cell
        (onset.delegate as! OnsetCoordinator).configure(cell: cell, view: self)
        (offset.delegate as! OffsetCoordinator).configure(cell: cell, view: self)
        ordinal.stringValue = String(cell.ordinal)
        onset.stringValue = formatTimestamp(timestamp: cell.onset)
        offset.stringValue = formatTimestamp(timestamp: cell.offset)

        if appState != nil {
            highlightObserver = AppStateObserver(object: appState!, cellItem: self)
        }
        onset.parentView = self
        offset.parentView = self

        cellTextField.configure(cellModel: cell)
        cellTextField.configureParentView(parentView: self)

        // Set Font Size
        onset.font = NSFont.systemFont(ofSize: Config.defaultCellTextSize * (parentView?.appState.zoomFactor ?? 1))
        offset.font = NSFont.systemFont(ofSize: Config.defaultCellTextSize * (parentView?.appState.zoomFactor ?? 1))
        cellTextField.font = NSFont.systemFont(ofSize: Config.defaultCellTextSize * (parentView?.appState.zoomFactor ?? 1))
        ordinal.font = NSFont.systemFont(ofSize: Config.defaultCellTextSize * (parentView?.appState.zoomFactor ?? 1))

        onset.sizeToFit()
        offset.sizeToFit()

        let offsetOrigin = NSPoint(x: cellTextField.frame.maxX - offset.frame.width, y: cellTextField.frame.maxY + 5)
        offset.frame.origin = offsetOrigin

        let onsetOrigin = NSPoint(x: offset.frame.minX - onset.frame.width - 5, y: cellTextField.frame.maxY + 5)
        onset.frame.origin = onsetOrigin

        self.parentView = parentView

        if cell.column!.isFinished {
            onset.isEnabled = false
            offset.isEnabled = false
            cellTextField.isEnabled = false
        } else {
            onset.isEnabled = true
            offset.isEnabled = true
            cellTextField.isEnabled = true
        }
    }

    func setHighlightActive() {
        view.layer?.borderColor = CGColor(red: 0, green: 255, blue: 0, alpha: 255)
        view.layer?.borderWidth = 3
        highlightStatus = CellHighlightState.active
    }

    func setHighlightPassed() {
        view.layer?.borderColor = CGColor(red: 255, green: 0, blue: 0, alpha: 255)
        view.layer?.borderWidth = 3
        highlightStatus = CellHighlightState.passed
    }

    func setHighlightOff() {
        view.layer?.borderColor = CGColor(red: 0, green: 0, blue: 0, alpha: 255)
        view.layer?.borderWidth = 3
        highlightStatus = CellHighlightState.off
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        configureCell(cell, parentView: parentView, appState: appState)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
//        argumentsCollectionView.register(ArgumentViewUIKit.self, forItemWithIdentifier: .init(ArgumentViewUIKit.identifier))
//        configureCell(cell, parentView: parentView, appState: appState)
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        setSelected()

        onset.nextResponder = offset
        cellTextField.updateToolTips()
    }

    override func prepareForReuse() {
        // Attach it to a dummy cell until that gets replaced
        cell = CellViewUIKit.dummyCell
        (onset.delegate as! OnsetCoordinator).configure(cell: cell, view: self)
        (offset.delegate as! OffsetCoordinator).configure(cell: cell, view: self)
        cellTextField.configure(cellModel: cell)
        lastEditedField = LastEditedField.none

        onset.isEnabled = true
        offset.isEnabled = true
        cellTextField.isEnabled = true

        setDeselected()
    }

    func setSelected() {
        if cell.isSelected {
            parentView?.deselectAllCells()
            if highlightStatus == .off {
                view.layer?.borderColor = CGColor(red: 0, green: 0, blue: 255, alpha: 255)
                view.layer?.borderWidth = 1
            }
            cell.isSelected = true
            cell.column?.sheetModel?.focusController.setFocusedCell(cell: cell)
        } else {
            setDeselected()
        }
    }

    func setDeselected() {
        view.layer?.borderWidth = 0
        cell.isSelected = false
    }

    func focusArgument(_ ip: IndexPath) {
        Logger.info(#function)
        parentView?.window?.makeFirstResponder(cellTextField)
        cellTextField.selectArgument(idx: ip.item)
    }

    func focusOnset() {
        Logger.info(#function)
        parentView?.window?.makeFirstResponder(onset)
    }

    func focusOffset() {
        Logger.info(#function)
        parentView?.window?.makeFirstResponder(offset)
    }

    func focusArguments() {
        Logger.info(#function)
        parentView?.window?.makeFirstResponder(cellTextField)
    }

    func focusNextArgument(_ argument: Argument) {
        Logger.info(#function)
        let selectedIndexPath: IndexPath
        if parentView != nil {
            selectedIndexPath = cell.getNextArgumentIndex(argument)
        } else {
            selectedIndexPath = IndexPath(item: 0, section: 0)
        }

        var focusObject: NSView? = nil
        if lastEditedField == LastEditedField.none {
            focusObject = onset
        } else if lastEditedField == LastEditedField.onset {
            focusObject = offset
        } else {
            let newIndexPath = IndexPath(item: selectedIndexPath.item, section: selectedIndexPath.section)
//            let nextArg = argumentsCollectionView?.item(at: newIndexPath) as! ArgumentViewUIKit
//            focusObject = nextArg.argumentValue
        }
        Logger.info("Focus next arg")
        parentView?.window?.makeFirstResponder(focusObject)
    }
}
