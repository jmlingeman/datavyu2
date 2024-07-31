import AppKit
import SwiftUI

class CellTimeTextField: NSTextField {
    var parentView: CellViewUIKit?

    override func becomeFirstResponder() -> Bool {
        guard super.becomeFirstResponder() else {
            return false
        }
        if let editor = currentEditor() {
            editor.perform(#selector(selectAll(_:)), with: self, afterDelay: 0)
        }
        if parentView != nil {
            parentView!.setSelected()
        }

        return true
    }

    override var acceptsFirstResponder: Bool {
        true
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

extension OnsetCoordinator: NSTextFieldDelegate, NSTextViewDelegate {
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

    func textView(_: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        print(#function)
        print(commandSelector)
        if commandSelector == #selector(NSResponder.insertBacktab) {
            let ip = self.parentView!.sheetModel.findCellIndexPath(cell_to_find: self.view!.cell)
            if ip != nil {
                (self.parentView!.delegate as! Coordinator).focusPrevCell(ip!)
            }
            self.view!.resignFirstResponder()
            return true
        }

        return false
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

extension OffsetCoordinator: NSTextFieldDelegate, NSTextViewDelegate {
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
