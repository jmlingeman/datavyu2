
import AppKit
import Foundation
import SwiftUI

class CellTextFormatter: Formatter {
    var cellTextController: CellTextController?
    var cell: CellModel?

    func configure(cellTextController: CellTextController, cell: CellModel) {
        self.cellTextController = cellTextController
        self.cell = cell
    }

    override func string(for obj: Any?) -> String? {
        guard let s = obj as? String else {
            return ""
        }
        return s
    }

    override func getObjectValue(_ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?, for string: String, errorDescription _: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        obj?.pointee = string as NSString
        return true
    }

    override func isPartialStringValid(_ partialString: String, newEditingString _: AutoreleasingUnsafeMutablePointer<NSString?>?, errorDescription _: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        Logger.info("formatting", partialString)

        // Ability to reset your field (otherwise you can't delete the content)
        // You can check if the field is empty later
        if partialString.isEmpty {
            return true
        }

        let sepCount = partialString.filter { c in
            String(c) == CellTextController.argumentSeperator
        }.count

        if sepCount != cell!.arguments.count - 1 {
            return false
        }

//        if partialString.contains(CellTextController.argumentSeperator) {
//            Logger.info("error: has comma")
//            return false
//        }

        // Optional: limit input length
        /*
         if partialString.characters.count>3 {
         return false
         }
         */

        return true
    }
}

class CellTextField: NSTextField {
    var cellModel: CellModel?
    var parentView: CellViewUIKit?
    var argumentView: ArgumentViewUIKit?

    var isEditing: Bool = false

    var lastIntrinsicSize = NSSize.zero
    var hasLastIntrinsicSize = false

    var cellTextController: CellTextController?

    var currentArgumentIndex: Int = 0

    var keyEventHandler: Any?

    func configure(cellModel: CellModel) {
        self.cellModel = cellModel
        delegate = self
        cellTextController = CellTextController(cell: cellModel)
        updateStringValue(cellTextController!.argumentString())

        (formatter as! CellTextFormatter).configure(cellTextController: cellTextController!, cell: self.cellModel!)
    }

    func updateStringValue(_ s: String) {
        DispatchQueue.main.async {
            self.stringValue = s
        }
    }

    func updateToolTips() {
        guard let textFieldCell = cell,
              let textFieldCellBounds = textFieldCell.controlView?.bounds
        else {
            return
        }
        let textBounds = textFieldCell.titleRect(forBounds: textFieldCellBounds)
        let textContainer = NSTextContainer()
        let layoutManager = NSLayoutManager()
        let textStorage = NSTextStorage()

        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        layoutManager.typesetterBehavior = NSLayoutManager.TypesetterBehavior.behavior_10_2_WithCompatibility

        textContainer.containerSize = textBounds.size
        textStorage.beginEditing()
        textStorage.setAttributedString(textFieldCell.attributedStringValue)
        textStorage.endEditing()

        for arg in cellModel!.arguments {
            let rangeCharacters = (textFieldCell.stringValue as NSString).range(of: arg.getDisplayString())

            var count = 0
            guard let rects: NSRectArray = layoutManager.rectArray(forCharacterRange: rangeCharacters,
                                                                   withinSelectedCharacterRange: rangeCharacters,
                                                                   in: textContainer,
                                                                   rectCount: &count)
            else {
                return
            }

            for i in 0 ... count {
                var rect = NSOffsetRect(rects[i], textBounds.origin.x, textBounds.origin.y)
                rect = convert(rect, to: self)
                addToolTip(rect, owner: arg.name, userData: nil)
            }
        }
    }

    func configureParentView(parentView: CellViewUIKit) {
        self.parentView = parentView
    }

    func selectArgument(idx: Int) {
        let extents = cellTextController!.getExtentOfArgument(idx: idx)
        Logger.info("Selecting \(idx)")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if self.currentEditor() != nil {
                self.currentEditor()?.selectedRange = NSRange(location: extents.start, length: extents.end - extents.start)
                self.currentArgumentIndex = idx
            }
        }
    }

    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)

        let cEditor = currentEditor() as? NSTextView
        let localPos = convert(event.locationInWindow, to: nil)
        let insertionPoint = cEditor?.characterIndexForInsertion(at: localPos)
        let location = cEditor?.selectedRange().location

        if cEditor?.string.count == insertionPoint {
            selectArgument(idx: 0)
        } else {
            let argIdx = cellTextController?.getArgIdxForIdx(idx: insertionPoint!)
            selectArgument(idx: argIdx!)
        }
    }

    override func becomeFirstResponder() -> Bool {
        guard super.becomeFirstResponder() else {
            return false
        }

        if parentView != nil {
            cellModel?.isSelected = true
            parentView!.setSelected()
        }

        selectArgument(idx: 0)

        keyEventHandler = NSEvent.addLocalMonitorForEvents(matching: NSEvent.EventTypeMask.keyDown) { event in
            let s = event.characters
            if s!.contains(CellTextController.argumentSeperator) {
                return nil
            }
            return event
        }

        updateToolTips()

        return true
    }

    override func resignFirstResponder() -> Bool {
        if keyEventHandler != nil {
            NSEvent.removeMonitor(keyEventHandler!)
        }
        keyEventHandler = nil
        guard super.resignFirstResponder() else {
            return false
        }
        return true
    }

//    override func textDidChange(_ notification: Notification) {
    ////        super.textDidChange(notification)
    //////        Logger.info("invalidate intrin")
    ////
    ////        Logger.info(self.stringValue, self.cellTextController)
    ////
    ////        self.cellTextController!.parseUpdates(newValue: self.stringValue)
    ////        self.updateStringValue(self.cellTextController!.argumentString())
    //////        super.invalidateIntrinsicContentSize()
    ////        Logger.info(self.stringValue)
//
//    }
}

extension CellTextField: NSTextFieldDelegate, NSTextViewDelegate {
    func textField(_: NSTextField, textView _: NSTextView, candidatesForSelectedRange _: NSRange) -> [Any]? {
        Logger.info("ARGUMENT: \(#function)")
        return nil
    }

    func textField(_: NSTextField, textView _: NSTextView, candidates: [NSTextCheckingResult], forSelectedRange _: NSRange) -> [NSTextCheckingResult] {
        Logger.info("ARGUMENT: \(#function)")
        return candidates
    }

    func textField(_: NSTextField, textView _: NSTextView, shouldSelectCandidateAt _: Int) -> Bool {
        Logger.info("ARGUMENT: \(#function)")
        return true
    }

    func controlTextDidBeginEditing(_: Notification) {
        Logger.info("ARGUMENT: \(#function)")
        isEditing = true
//        parentView!.lastEditedField = LastEditedField.arguments
    }

    func controlTextDidEndEditing(_ obj: Notification) {
        Logger.info("ARGUMENT: \(#function)")
        isEditing = false
        guard
            let textField = obj.object as? NSTextField,
            !textField.isFocused
        else {
            return
        }
        cellTextController?.parseUpdates(newValue: stringValue)
        updateStringValue(cellTextController!.argumentString())
    }

    func control(_: NSControl, textView _: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        Logger.info("ARGUMENT: \(#function)")
        Logger.info(commandSelector)

        return true
    }

    func controlTextDidChange(_: Notification) {
        Logger.info(self)
        Logger.info("ARGUMENT: \(#function)")
//        parentView!.lastEditedField = LastEditedField.arguments
        cellTextController?.parseUpdates(newValue: stringValue)
        updateStringValue(cellTextController!.argumentString())
        updateToolTips()
//        invalidateIntrinsicContentSize()
    }

    func control(_: NSControl, textShouldBeginEditing _: NSText) -> Bool {
        Logger.info("ARGUMENT: \(#function)")
        return true
    }

    func control(_: NSControl, textShouldEndEditing _: NSText) -> Bool {
        Logger.info("ARGUMENT: \(#function)")
        return true
    }

    func textView(_: NSTextView, willChangeSelectionFromCharacterRange oldSelectedCharRange: NSRange, toCharacterRange newSelectedCharRange: NSRange) -> NSRange {
        if oldSelectedCharRange.length == 0, newSelectedCharRange.length == 0, !isEditing {
            let extent = cellTextController!.getExtentForIdx(idx: oldSelectedCharRange.lowerBound)
            return NSRange(location: extent.start, length: extent.end - extent.start)
        }

        return newSelectedCharRange
    }

    func textView(_: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        Logger.info(#function)
        Logger.info(commandSelector)
        if commandSelector == #selector(insertTab) {
            if self.currentArgumentIndex + 1 < self.cellModel!.arguments.count {
                self.selectArgument(idx: self.currentArgumentIndex + 1)
                return true
            } else {
                let ip = self.parentView!.parentView!.sheetModel.findCellIndexPath(cell_to_find: self.parentView!.cell)
                if ip != nil {
                    (self.parentView!.parentView!.delegate as! Coordinator).focusNextCell(ip!)
                }
                self.resignFirstResponder()
                return true
            }
        } else if commandSelector == #selector(insertBacktab) {
            if self.currentArgumentIndex - 1 >= 0 {
                self.selectArgument(idx: self.currentArgumentIndex - 1)
                return true
            } else {
                self.parentView!.focusOffset()
                self.resignFirstResponder()
                return true
            }
        } else if commandSelector == #selector(moveDown) {
            let ip = self.parentView!.parentView!.sheetModel.findVisibleCellIndexPath(cell_to_find: self.parentView!.cell)
            if ip != nil {
                (self.parentView!.parentView!.delegate as! Coordinator).focusNextCell(ip!)
                (self.parentView!.parentView!.delegate as! Coordinator).focusField(IndexPath(item: self.currentArgumentIndex, section: 0))
            }
            let _ = self.resignFirstResponder()
            return true
        } else if commandSelector == #selector(moveUp) {
            var ip = self.parentView!.parentView!.sheetModel.findVisibleCellIndexPath(cell_to_find: self.parentView!.cell)

            if ip != nil {
                ip!.item = ip!.item - 1
                if ip!.item < 0 {
                    return true
                }
                (self.parentView!.parentView!.delegate as! Coordinator).focusCell(ip!)
                (self.parentView!.parentView!.delegate as! Coordinator).focusField(IndexPath(item: self.currentArgumentIndex, section: 0))
                return true
            }
            let _ = self.resignFirstResponder()
        } else if commandSelector == #selector(moveRight) {
            var ip = self.parentView!.parentView!.sheetModel.findCellInNextColumnIndexPath(cell: self.parentView!.cell)

            if ip != nil {
                (self.parentView!.parentView!.delegate as! Coordinator).focusNextCell(ip!)
                (self.parentView!.parentView!.delegate as! Coordinator).focusField(IndexPath(item: self.currentArgumentIndex, section: 0))
                return true
            }
            let _ = self.resignFirstResponder()
        } else if commandSelector == #selector(moveLeft) {
            var ip = self.parentView!.parentView!.sheetModel.findCellInPrevColumnIndexPath(cell: self.parentView!.cell)

            if ip != nil {
                (self.parentView!.parentView!.delegate as! Coordinator).focusNextCell(ip!)
                (self.parentView!.parentView!.delegate as! Coordinator).focusField(IndexPath(item: self.currentArgumentIndex, section: 0))
                return true
            }
            let _ = self.resignFirstResponder()
        }

        return false
    }
}

public extension NSTextField {
    var isFocused: Bool {
        if
            window?.firstResponder is NSTextView,
            let fieldEditor = window?.fieldEditor(false, for: nil),
            let delegate = fieldEditor.delegate as? NSTextField,
            self == delegate
        {
            return true
        }
        return false
    }
}
