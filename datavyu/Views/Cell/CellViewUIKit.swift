//
//  CellViewUIKit.swift
//  datavyu
//
//  Created by Jesse Lingeman on 1/30/24.
//

import AppKit
import SwiftUI

class CellViewUIKit: NSCollectionViewItem {
    static let identifier: String = "CellViewUIKit"

    @IBOutlet var onset: CellTimeTextField!
    @IBOutlet var offset: CellTimeTextField!
    @IBOutlet var ordinal: NSTextField!
    @IBOutlet var argumentsCollectionView: NSCollectionView!

    var onsetCoordinator: OnsetCoordinator?
    var offsetCoordinator: OffsetCoordinator?

    var argumentSizes: [IndexPath: NSSize]

    var parentView: TemporalCollectionAppKitView?

    var lastEditedField: LastEditedField = .none

    @ObservedObject var cell: CellModel
    let dummyCell = CellModel(column: ColumnModel(sheetModel: SheetModel(sheetName: "temp"), columnName: "temp"))

    override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?) {
        cell = dummyCell
        ordinal = NSTextField()
        onset = CellTimeTextField()
        offset = CellTimeTextField()
        argumentsCollectionView = NSCollectionView()
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
        let selectedIndexPaths = argumentsCollectionView?.selectionIndexPaths
        return selectedIndexPaths?.first?.item == cell.arguments.count - 1
    }

    func configureCell(_ cell: CellModel, parentView: TemporalCollectionAppKitView?) {
//        print("CONFIGURING CELL")
        self.cell = cell
        (onset.delegate as! OnsetCoordinator).configure(cell: cell, view: self)
        (offset.delegate as! OffsetCoordinator).configure(cell: cell, view: self)
        ordinal.stringValue = String(cell.ordinal)
        onset.stringValue = formatTimestamp(timestamp: cell.onset)
        offset.stringValue = formatTimestamp(timestamp: cell.offset)

        onset.parentView = self
        offset.parentView = self

        argumentsCollectionView.delegate = self
        argumentsCollectionView.dataSource = self

        self.parentView = parentView

        if cell.column.isFinished {
            onset.isEnabled = false
            offset.isEnabled = false
        } else {
            onset.isEnabled = true
            offset.isEnabled = true
        }

//        print("CONFIGURED CELL \(self.onset) \(self.offset) \(self.cell) \(cell.ordinal) \(cell)")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        argumentsCollectionView.register(ArgumentViewUIKit.self, forItemWithIdentifier: .init(ArgumentViewUIKit.identifier))
        configureCell(cell, parentView: parentView)
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
        offset.nextResponder = argumentsCollectionView
    }

    override func prepareForReuse() {
        // Attach it to a dummy cell until that gets replaced
        cell = dummyCell
        (onset.delegate as! OnsetCoordinator).configure(cell: cell, view: self)
        (offset.delegate as! OffsetCoordinator).configure(cell: cell, view: self)
        argumentsCollectionView.delegate = nil
        argumentsCollectionView.dataSource = nil
        lastEditedField = LastEditedField.none

        onset.isEnabled = true
        offset.isEnabled = true

        setDeselected()
    }

    func setSelected() {
        parentView?.deselectAllCells()
        view.layer?.borderColor = CGColor(red: 255, green: 0, blue: 0, alpha: 255)
        view.layer?.borderWidth = 1
        isSelected = true
        parentView?.lastSelectedCellModel = cell
    }

    func setDeselected() {
        view.layer?.borderWidth = 0
        isSelected = false
    }

    func focusArgument(_ ip: IndexPath) {
        print(#function)
        let nextArg = argumentsCollectionView?.item(at: ip) as! ArgumentViewUIKit
        print("selecting arg \(nextArg)")
        parentView?.lastEditedArgument = nextArg.argument
        parentView?.window?.makeFirstResponder(nextArg.argumentValue)
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
            let nextArg = argumentsCollectionView?.item(at: newIndexPath) as! ArgumentViewUIKit
            focusObject = nextArg.argumentValue
        }
        print("Focus next arg")
        parentView?.window?.makeFirstResponder(focusObject)
    }
}

extension CellViewUIKit: NSCollectionViewDelegate {
    func collectionView(_: NSCollectionView, didSelectItemsAt _: Set<IndexPath>) {
        print("Arg Clicked")
    }
}

extension CellViewUIKit: NSCollectionViewDataSource {
    func collectionView(_: NSCollectionView, numberOfItemsInSection _: Int) -> Int {
        cell.arguments.count
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: .init(ArgumentViewUIKit.identifier), for: indexPath) as! ArgumentViewUIKit
//        print("Cell \(cell.column.columnName) \(cell.ordinal) args: \(cell.arguments[0].value)")
        let argument = cell.arguments[indexPath.item]
        item.configureCell(with: argument)
        item.configureParentView(with: self)

        // TODO: fix this
        argumentSizes[indexPath] = NSSize(width: item.argumentValue.preferredMaxLayoutWidth, height: 50)

        return item
    }
}

extension CellViewUIKit: NSCollectionViewDelegateFlowLayout {
    func collectionView(_: NSCollectionView, layout _: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
//        let item = collectionView.makeItem(withIdentifier: .init(ArgumentViewUIKit.identifier), for: indexPath) as! ArgumentViewUIKit
        let size = NSSize(
            width: max(50, argumentSizes[indexPath]?.width ?? 0),
            height: max(50, argumentSizes[indexPath]?.height ?? 0)
        )
        return size
    }
}

@objc class OnsetCoordinator: NSObject {
    var cell: CellModel?
    var view: CellViewUIKit?
    var parentView: TemporalCollectionAppKitView?
    var onsetValue: String?

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
        parentView?.lastSelectedCellModel = cell

        print("Set focus object to: \(view?.onset)")
    }

    func controlTextDidEndEditing(_ obj: Notification) {
        print(#function)
        if let textField = obj.object as? NSTextField {
            if textField.stringValue != onsetValue {
                let timestampStr = textField.stringValue
                let timestamp = timestringToTimestamp(timestring: timestampStr)
                view?.lastEditedField = LastEditedField.onset
                print("SETTING ONSET TO \(timestamp)")
                cell!.setOnset(onset: timestamp)
            }
        }
        parentView?.lastSelectedCellModel = cell
//        self.view?.setDeselected()
    }

    func controlTextDidChange(_: Notification) {
        print(self)
        print(#function)
        view?.lastEditedField = LastEditedField.onset
        parentView?.lastSelectedCellModel = cell
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
    var parentView: TemporalCollectionAppKitView?
    var offsetValue: String?

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
        parentView?.lastSelectedCellModel = cell
    }

    func controlTextDidEndEditing(_ obj: Notification) {
        print(#function)
        if let textField = obj.object as? NSTextField {
            if textField.stringValue != offsetValue {
                let timestampStr = textField.stringValue
                let timestamp = timestringToTimestamp(timestring: timestampStr)
                print("SETTING OFFSET TO \(timestamp)")
                view?.lastEditedField = LastEditedField.offset
                parentView?.lastSelectedCellModel = cell
                cell!.setOffset(offset: timestamp)
            }
        }
    }

    func controlTextDidChange(_: Notification) {
        print(self)
        print(#function)
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
