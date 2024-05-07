//
//  ArgumentCellView.swift
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
    
    var focusObject: NSView?
    var focusPath: IndexPath?
    
    var lastEditedField: LastEditedField = LastEditedField.none
    
    @ObservedObject var cell: CellModel
    let dummyCell = CellModel(column: ColumnModel(sheetModel: SheetModel(sheetName: "temp"), columnName: "temp"))
    
    override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?) {
        self.cell = dummyCell
        self.ordinal = NSTextField()
        self.onset = CellTimeTextField()
        self.offset = CellTimeTextField()
        self.argumentsCollectionView = NSCollectionView()
        self.argumentSizes = [IndexPath: NSSize]()

        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        ValueTransformer.setValueTransformer(TimestampTransformer(), forName: .classNameTransformerName)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func resetFocus() {
        if focusObject != nil {
//            focusObject?.window?.makeFirstResponder(focusObject?.nextResponder)
        }
    }
    
    func numArguments() -> Int {
        return self.cell.arguments.count
    }
    
    func isLastArgument() -> Bool {
        let selectedIndexPaths = self.argumentsCollectionView?.selectionIndexPaths
        return selectedIndexPaths?.first?.item == cell.arguments.count - 1
    }
    
    func configureCell(_ cell: CellModel, parentView: TemporalCollectionAppKitView?) {
//        print("CONFIGURING CELL")
        self.cell = cell
        (self.onset.delegate as! OnsetCoordinator).configure(cell: cell, view: self)
        (self.offset.delegate as! OffsetCoordinator).configure(cell: cell, view: self)
        self.ordinal.stringValue = String(cell.ordinal)
        self.onset.stringValue = formatTimestamp(timestamp: cell.onset)
        self.offset.stringValue = formatTimestamp(timestamp: cell.offset)
        
        self.onset.parentView = self
        self.offset.parentView = self
        
        self.argumentsCollectionView.delegate = self
        self.argumentsCollectionView.dataSource = self
        
        self.parentView = parentView

//        print("CONFIGURED CELL \(self.onset) \(self.offset) \(self.cell) \(cell.ordinal) \(cell)")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.argumentsCollectionView.register(ArgumentViewUIKit.self, forItemWithIdentifier: .init(ArgumentViewUIKit.identifier))
        self.configureCell(self.cell, parentView: self.parentView)
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        if self.isSelected {
            self.setSelected()
        } else {
            self.setDeselected()
        }
        
        if self.isSelected {
//            self.selectNextField()
        }
        
        self.onset.nextResponder = self.offset
        self.offset.nextResponder = self.argumentsCollectionView
    }
    
    override func prepareForReuse() {
        // Attach it to a dummy cell until that gets replaced
        self.cell = dummyCell
        (self.onset.delegate as! OnsetCoordinator).configure(cell: cell, view: self)
        (self.offset.delegate as! OffsetCoordinator).configure(cell: cell, view: self)
        self.argumentsCollectionView.delegate = nil
        self.argumentsCollectionView.dataSource = nil
        self.focusObject = nil
        self.lastEditedField = LastEditedField.none
        
        self.setDeselected()
    }
    
    func setSelected() {
        self.parentView?.deselectAllCells()
        self.view.layer?.borderColor = CGColor(red: 255, green: 0, blue: 0, alpha: 255)
        self.view.layer?.borderWidth = 1
        self.isSelected = true
        self.parentView?.lastSelectedCellModel = self.cell
    }
    
    func setDeselected() {
        self.view.layer?.borderWidth = 0
        self.isSelected = false
        
    }
    
    override func keyDown(with event: NSEvent) {
        print("CELL KEY GOT")
    }
    
    func focusArgument(_ ip: IndexPath) {
        print(#function)
        let nextArg = self.argumentsCollectionView?.item(at: ip) as! ArgumentViewUIKit
        print("selecting arg \(nextArg)")
        self.focusObject = nextArg.argumentValue
        print(3)
        self.parentView?.window?.makeFirstResponder(self.focusObject)

        
        print(4)
    }
    
    func focusOnset() {
        print(#function)
        self.parentView?.window?.makeFirstResponder(self.onset)
    }
    
    func focusOffset() {
        print(#function)
        self.parentView?.window?.makeFirstResponder(self.offset)
    }
    
    func focusNextArgument(_ argument: Argument) {
        print(#function)
        let selectedIndexPath: IndexPath
        if parentView != nil {
            selectedIndexPath = cell.getNextArgumentIndex(argument)
        } else {
            selectedIndexPath = IndexPath(item: 0, section: 0)
        }
        
        if self.focusObject == nil {
            self.focusObject = self.onset
        } else {
            let newIndexPath = IndexPath(item: selectedIndexPath.item, section: selectedIndexPath.section)
            let nextArg = self.argumentsCollectionView?.item(at: newIndexPath) as! ArgumentViewUIKit
            self.focusObject = nextArg.argumentValue
        }
        print("Focus next arg")
        self.parentView?.window?.makeFirstResponder(self.focusObject)
    }
}

extension CellViewUIKit: NSCollectionViewDelegate {
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        print("Arg Clicked")
    }
}

extension CellViewUIKit: NSCollectionViewDataSource {
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return cell.arguments.count
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
    
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
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
        
    func textField(_ textField: NSTextField, textView: NSTextView, candidatesForSelectedRange selectedRange: NSRange) -> [Any]? {
        print(#function)
        return nil
    }
    
    func textField(_ textField: NSTextField, textView: NSTextView, candidates: [NSTextCheckingResult], forSelectedRange selectedRange: NSRange) -> [NSTextCheckingResult] {
        print(#function)
        return candidates
    }
    
    func textField(_ textField: NSTextField, textView: NSTextView, shouldSelectCandidateAt index: Int) -> Bool {
        print(#function)
        return true
    }
        
    func controlTextDidBeginEditing(_ obj: Notification) {
        print(#function)
        self.view?.isSelected = true
        self.view?.setSelected()
        
        onsetValue = view?.onset.stringValue
        view?.focusObject = view?.onset
                    
        print("Set focus object to: \(view?.onset)")
    }
    
    func controlTextDidEndEditing(_ obj: Notification) {
        print(#function)
        if let textField = obj.object as? NSTextField {
            if textField.stringValue != self.onsetValue {
                let timestampStr = textField.stringValue
                let timestamp = timestringToTimestamp(timestring: timestampStr)
                self.view?.lastEditedField = LastEditedField.onset
                print("SETTING ONSET TO \(timestamp)")
                cell!.setOnset(onset: timestamp)
            }
        }
        self.parentView?.lastSelectedCellModel = self.cell
//        self.view?.setDeselected()
    }
    
    func controlTextDidChange(_ obj: Notification) {
        print(self)
        print(#function)
    }
    
    func control(_ control: NSControl, textShouldBeginEditing fieldEditor: NSText) -> Bool {
        print(#function)
        return true
    }
    
    func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
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
        self.parentView = view.parentView
    }
}

extension OffsetCoordinator: NSTextFieldDelegate {
    
    func textField(_ textField: NSTextField, textView: NSTextView, candidatesForSelectedRange selectedRange: NSRange) -> [Any]? {
        print(#function)
        return nil
    }
    
    func textField(_ textField: NSTextField, textView: NSTextView, candidates: [NSTextCheckingResult], forSelectedRange selectedRange: NSRange) -> [NSTextCheckingResult] {
        print(#function)
        return candidates
    }
    
    func textField(_ textField: NSTextField, textView: NSTextView, shouldSelectCandidateAt index: Int) -> Bool {
        print(#function)
        return true
    }
    
    func controlTextDidBeginEditing(_ obj: Notification) {
        print(#function)
        view?.setSelected()
        view?.focusObject = view?.offset
        self.parentView?.lastSelectedCellModel = self.cell
    }
    
    func controlTextDidEndEditing(_ obj: Notification) {
        print(#function)
        if let textField = obj.object as? NSTextField {
            if textField.stringValue != self.offsetValue {
                self.view?.focusObject = textField
                let timestampStr = textField.stringValue
                let timestamp = timestringToTimestamp(timestring: timestampStr)
                print("SETTING OFFSET TO \(timestamp)")
                self.view?.lastEditedField = LastEditedField.offset
                self.parentView?.lastSelectedCellModel = self.cell
                cell!.setOffset(offset: timestamp)
            }
        }
    }
    
    func controlTextDidChange(_ obj: Notification) {
        print(self)
        print(#function)

    }
    
    func control(_ control: NSControl, textShouldBeginEditing fieldEditor: NSText) -> Bool {
        print(#function)
        return true
    }
    
    func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
        print(#function)
        return true
    }
}
