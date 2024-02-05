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
    
    @IBOutlet var onset: NSTextField!
    @IBOutlet var offset: NSTextField!
    @IBOutlet var ordinal: NSTextField!
    @IBOutlet var argumentsCollectionView: NSCollectionView!
    
    var onsetCoordinator: OnsetCoordinator?
    var offsetCoordinator: OffsetCoordinator?
    
    var argumentSizes: [IndexPath: NSSize]
    
    @ObservedObject var cell: CellModel
    
    override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?) {
        self.cell = CellModel(column: ColumnModel(sheetModel: SheetModel(sheetName: "temp"), columnName: "temp"))
        self.ordinal = NSTextField()
        self.onset = NSTextField()
        self.offset = NSTextField()
        self.argumentsCollectionView = NSCollectionView()
        self.argumentSizes = [IndexPath: NSSize]()

        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        ValueTransformer.setValueTransformer(TimestampTransformer(), forName: .classNameTransformerName)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureCell(_ cell: CellModel) {
//        print("CONFIGURING CELL")
        self.cell = cell
        (self.onset.delegate as! OnsetCoordinator).configure(cell: cell)
        (self.offset.delegate as! OffsetCoordinator).configure(cell: cell)
        self.ordinal.stringValue = String(cell.ordinal)
        self.onset.stringValue = formatTimestamp(timestamp: cell.onset)
        self.offset.stringValue = formatTimestamp(timestamp: cell.offset)
        
        self.argumentsCollectionView.delegate = self
        self.argumentsCollectionView.dataSource = self

//        print("CONFIGURED CELL \(self.onset) \(self.offset) \(self.cell) \(cell.ordinal) \(cell)")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.argumentsCollectionView.register(ArgumentViewUIKit.self, forItemWithIdentifier: .init(ArgumentViewUIKit.identifier))
        self.configureCell(self.cell)
    }
    
    override func prepareForReuse() {
        // Attach it to a dummy cell until that gets replaced
        self.cell = CellModel(column: ColumnModel(sheetModel: SheetModel(sheetName: "dummy"), columnName: "dummy"))
        (self.onset.delegate as! OnsetCoordinator).configure(cell: cell)
        (self.offset.delegate as! OffsetCoordinator).configure(cell: cell)
        self.argumentsCollectionView.delegate = nil
        self.argumentsCollectionView.dataSource = nil
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
        print("Cell \(cell.column.columnName) \(cell.ordinal) args: \(cell.arguments[0].value)")
        let argument = cell.arguments[indexPath.item]
        item.configureCell(with: argument)
        
        // TODO: fix this
        argumentSizes[indexPath] = NSSize(width: item.argumentValue.preferredMaxLayoutWidth, height: 50)
        
        return item
    }
}

extension CellViewUIKit: NSCollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
//        let item = collectionView.makeItem(withIdentifier: .init(ArgumentViewUIKit.identifier), for: indexPath) as! ArgumentViewUIKit
        print(argumentSizes)
        let size = NSSize(
            width: max(50, argumentSizes[indexPath]?.width ?? 0),
            height: max(50, argumentSizes[indexPath]?.height ?? 0)
        )
        print(indexPath, size)
        return size
    }
}

@objc class OnsetCoordinator: NSObject {
    var cell: CellModel?
    
    override init() {
        super.init()
    }
    
    init(cell: CellModel) {
        self.cell = cell
    }
    
    func configure(cell: CellModel) {
        self.cell = cell
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
    }
    
    func controlTextDidEndEditing(_ obj: Notification) {
        print(#function)
        if let textField = obj.object as? NSTextField {
            let timestampStr = textField.stringValue
            let timestamp = timestringToTimestamp(timestring: timestampStr)
            print("SETTING ONSET TO \(timestamp)")
            cell!.setOnset(onset: timestamp)
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

@objc class OffsetCoordinator: NSObject {
    var cell: CellModel?
    
    override init() {
        super.init()
    }
    
    init(cell: CellModel) {
        self.cell = cell
    }
    
    func configure(cell: CellModel) {
        self.cell = cell
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
    }
    
    func controlTextDidEndEditing(_ obj: Notification) {
        print(#function)
        print("CELL: \(self.cell)")
        if let textField = obj.object as? NSTextField {
            let timestampStr = textField.stringValue
            let timestamp = timestringToTimestamp(timestring: timestampStr)
            print("SETTING OFFSET TO \(timestamp)")
            cell!.setOffset(offset: timestamp)
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
