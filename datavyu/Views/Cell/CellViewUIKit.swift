//
//  CellViewUIKit.swift
//  datavyu
//
//  Created by Jesse Lingeman on 1/30/24.
//

import AppKit
import SwiftUI

enum CellHighlightState {
    case active
    case passed
    case off
}

class CellViewUIKit: NSCollectionViewItem {
    static let identifier: String = "CellViewUIKit"

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
    let dummyCell = CellModel(column: ColumnModel(sheetModel: SheetModel(sheetName: "temp"), columnName: "temp"))

    override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?) {
        cell = dummyCell
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
//        print("CONFIGURING CELL")

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
        } else {
            onset.isEnabled = true
            offset.isEnabled = true
        }

//        print("CONFIGURED CELL \(self.onset) \(self.offset) \(self.cell) \(cell.ordinal) \(cell)")
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

    override func viewDidLoad() {
        super.viewDidLoad()
//        argumentsCollectionView.register(ArgumentViewUIKit.self, forItemWithIdentifier: .init(ArgumentViewUIKit.identifier))
        configureCell(cell, parentView: parentView, appState: appState)
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        if isSelected {
            setSelected()
        } else {
            setDeselected()
        }

        if isSelected {
//            self.selectNextField()
        }

        onset.nextResponder = offset
        cellTextField.updateToolTips()
    }

    override func prepareForReuse() {
        // Attach it to a dummy cell until that gets replaced
        cell = dummyCell
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
        parentView?.deselectAllCells()
        if highlightStatus == .off {
            view.layer?.borderColor = CGColor(red: 0, green: 0, blue: 255, alpha: 255)
            view.layer?.borderWidth = 1
        }
        isSelected = true
        cell.column?.sheetModel?.setSelectedCell(selectedCell: cell)
    }

    func setDeselected() {
        view.layer?.borderWidth = 0
        isSelected = false
    }

    func focusArgument(_ ip: IndexPath) {
        print(#function)
        parentView?.window?.makeFirstResponder(cellTextField)
        cellTextField.selectArgument(idx: ip.item)
    }

    func focusOnset() {
        print(#function)
        parentView?.window?.makeFirstResponder(onset)
    }

    func focusOffset() {
        print(#function)
        parentView?.window?.makeFirstResponder(offset)
    }

    func focusNextArgument(_ argument: Argument) {
        print(#function)
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
        print("Focus next arg")
        parentView?.window?.makeFirstResponder(focusObject)
    }
}

@objc class OnsetCoordinator: NSObject {
    var cell: CellModel?
    var view: CellViewUIKit?
    var parentView: SheetCollectionAppKitView?
    var onsetValue: String?
    var isEdited = false

    override init() {
        super.init()
    }

    init(cell: CellModel, view: CellViewUIKit) {
        self.cell = cell
        self.view = view
    }

    func configure(cell: CellModel, view: CellViewUIKit) {
        self.cell = cell
        self.view = view
    }
}

extension OnsetCoordinator: NSTextFieldDelegate {
    func textField(_: NSTextField, textView _: NSTextView, candidatesForSelectedRange _: NSRange) -> [Any]? {
        print(#function)
        return nil
    }

    func textField(_: NSTextField, textView _: NSTextView, candidates: [NSTextCheckingResult], forSelectedRange _: NSRange) -> [NSTextCheckingResult] {
        print(#function)
        return candidates
    }

    func textField(_: NSTextField, textView _: NSTextView, shouldSelectCandidateAt _: Int) -> Bool {
        print(#function)
        return true
    }

    func controlTextDidBeginEditing(_: Notification) {
        print(#function)
        view?.isSelected = true
        view?.setSelected()

        onsetValue = view?.onset.stringValue

        view?.lastEditedField = LastEditedField.onset
        parentView?.sheetModel.setSelectedCell(selectedCell: cell)

        print("Set focus object to: \(view?.onset)")
    }

    func controlTextDidEndEditing(_ obj: Notification) {
        print(#function)
        if let textField = obj.object as? NSTextField {
            if isEdited, timestringToTimestamp(timestring: textField.stringValue) != cell!.onset {
                let timestampStr = textField.stringValue
                let timestamp = timestringToTimestamp(timestring: timestampStr)
                view?.lastEditedField = LastEditedField.onset
                print("SETTING ONSET TO \(timestamp)")
                textField.stringValue = formatTimestamp(timestamp: cell!.onset)
                cell!.setOnset(onset: timestamp)
            } else if timestringToTimestamp(timestring: textField.stringValue) != cell!.onset {
                textField.stringValue = formatTimestamp(timestamp: cell!.onset)
            }
            isEdited = false
        }
        parentView?.sheetModel.setSelectedCell(selectedCell: cell)
//        self.view?.setDeselected()
    }

    func controlTextDidChange(_: Notification) {
        print(self)
        print(#function)
        isEdited = true
        view?.lastEditedField = LastEditedField.onset
        parentView?.sheetModel.setSelectedCell(selectedCell: cell)
    }

    func control(_: NSControl, textShouldBeginEditing _: NSText) -> Bool {
        print(#function)
        return true
    }

    func control(_: NSControl, textShouldEndEditing _: NSText) -> Bool {
        print(#function)
        return true
    }
}

@objc class OffsetCoordinator: NSObject {
    var cell: CellModel?
    var view: CellViewUIKit?
    var parentView: SheetCollectionAppKitView?
    var offsetValue: String?
    var isEdited = false

    override init() {
        super.init()
    }

    init(cell: CellModel, view: CellViewUIKit) {
        self.cell = cell
        self.view = view
    }

    func configure(cell: CellModel, view: CellViewUIKit) {
        self.cell = cell
        self.view = view
        parentView = view.parentView
    }
}

extension OffsetCoordinator: NSTextFieldDelegate {
    func textField(_: NSTextField, textView _: NSTextView, candidatesForSelectedRange _: NSRange) -> [Any]? {
        print(#function)
        return nil
    }

    func textField(_: NSTextField, textView _: NSTextView, candidates: [NSTextCheckingResult], forSelectedRange _: NSRange) -> [NSTextCheckingResult] {
        print(#function)
        return candidates
    }

    func textField(_: NSTextField, textView _: NSTextView, shouldSelectCandidateAt _: Int) -> Bool {
        print(#function)
        return true
    }

    func controlTextDidBeginEditing(_: Notification) {
        print(#function)
        view?.setSelected()
        view?.lastEditedField = LastEditedField.offset
        parentView?.sheetModel.setSelectedCell(selectedCell: cell)
    }

    func controlTextDidEndEditing(_ obj: Notification) {
        print(#function)
        if let textField = obj.object as? NSTextField {
            if isEdited, timestringToTimestamp(timestring: textField.stringValue) != cell!.offset {
                let timestampStr = textField.stringValue
                let timestamp = timestringToTimestamp(timestring: timestampStr)
                view?.lastEditedField = LastEditedField.offset
                parentView?.sheetModel.setSelectedCell(selectedCell: cell)
                textField.stringValue = formatTimestamp(timestamp: cell!.offset)
                cell!.setOffset(offset: timestamp)
            } else if timestringToTimestamp(timestring: textField.stringValue) != cell!.offset {
                textField.stringValue = formatTimestamp(timestamp: cell!.offset)
            }
            isEdited = false
        }
    }

    func controlTextDidChange(_: Notification) {
        print(self)
        print(#function)
        isEdited = true
    }

    func control(_: NSControl, textShouldBeginEditing _: NSText) -> Bool {
        print(#function)
        return true
    }

    func control(_: NSControl, textShouldEndEditing _: NSText) -> Bool {
        print(#function)
        return true
    }
}
