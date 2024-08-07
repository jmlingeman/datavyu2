
import AppKit
import Foundation
import SwiftUI

class CodeRowTextFormatter: Formatter {
    var textController: CodeEditorRowTextController?
    var column: ColumnModel?

    func configure(textController: CodeEditorRowTextController, column: ColumnModel) {
        self.textController = textController
        self.column = column
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
        print("formatting", partialString)

        // Ability to reset your field (otherwise you can't delete the content)
        // You can check if the field is empty later
        if partialString.isEmpty {
            return true
        }

        let sepCount = partialString.filter { c in
            String(c) == CellTextController.argumentSeperator
        }.count

        if sepCount != column!.arguments.count - 1 {
            return false
        }

//        if partialString.contains(CellTextController.argumentSeperator) {
//            print("error: has comma")
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

struct CodeRowTextFieldView: NSViewRepresentable {
    @ObservedObject var column: ColumnModel
    typealias NSViewType = NSTextField

    func makeNSView(context _: Context) -> NSTextField {
        let view = CodeRowTextField()
        view.configure(column: column)
        return view
    }

    func updateNSView(_: NSTextField, context _: Context) {}
}

class CodeRowTextField: NSTextField {
    var column: ColumnModel?

    var isEditing: Bool = false

    var lastIntrinsicSize = NSSize.zero
    var hasLastIntrinsicSize = false

    var textController: CodeEditorRowTextController?

    var currentArgumentIndex: Int = 0

    var keyEventHandler: Any?

    func configure(column: ColumnModel) {
        self.column = column
        delegate = self
        textController = CodeEditorRowTextController(column: column)
        updateStringValue(textController!.rowString())

        formatter = CodeRowTextFormatter()
        (formatter as! CodeRowTextFormatter).configure(textController: textController!, column: column)
    }

    func updateStringValue(_ s: String) {
        DispatchQueue.main.async {
            self.stringValue = s
        }
    }

    func selectArgument(idx: Int) {
        let extents = textController!.getExtentOfArgument(idx: idx)
        print("Selecting \(idx)")
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
            let argIdx = textController?.getArgIdxForIdx(idx: insertionPoint!)
            selectArgument(idx: argIdx!)
        }
    }

    override func becomeFirstResponder() -> Bool {
        guard super.becomeFirstResponder() else {
            return false
        }

        selectArgument(idx: 0)

        keyEventHandler = NSEvent.addLocalMonitorForEvents(matching: NSEvent.EventTypeMask.keyDown) { event in
            let s = event.characters
            if s!.contains(CellTextController.argumentSeperator) {
                return nil
            }
            return event
        }

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
    //////        print("invalidate intrin")
    ////
    ////        print(self.stringValue, self.cellTextController)
    ////
    ////        self.cellTextController!.parseUpdates(newValue: self.stringValue)
    ////        self.updateStringValue(self.cellTextController!.argumentString())
    //////        super.invalidateIntrinsicContentSize()
    ////        print(self.stringValue)
//
//    }
}

extension CodeRowTextField: NSTextFieldDelegate, NSTextViewDelegate {
    func textField(_: NSTextField, textView _: NSTextView, candidatesForSelectedRange _: NSRange) -> [Any]? {
        print("ARGUMENT: \(#function)")
        return nil
    }

    func textField(_: NSTextField, textView _: NSTextView, candidates: [NSTextCheckingResult], forSelectedRange _: NSRange) -> [NSTextCheckingResult] {
        print("ARGUMENT: \(#function)")
        return candidates
    }

    func textField(_: NSTextField, textView _: NSTextView, shouldSelectCandidateAt _: Int) -> Bool {
        print("ARGUMENT: \(#function)")
        return true
    }

    func controlTextDidBeginEditing(_: Notification) {
        print("ARGUMENT: \(#function)")
        isEditing = true
//        parentView!.lastEditedField = LastEditedField.arguments
    }

    func controlTextDidEndEditing(_ obj: Notification) {
        print("ARGUMENT: \(#function)")
        isEditing = false
        guard
            let textField = obj.object as? NSTextField,
            !textField.isFocused
        else {
            return
        }
        textController?.parseUpdates(newValue: stringValue)
        updateStringValue(textController!.rowString())
    }

    func control(_: NSControl, textView _: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        print("ARGUMENT: \(#function)")
        print(commandSelector)

        return true
    }

    func controlTextDidChange(_: Notification) {
        print(self)
        print("ARGUMENT: \(#function)")
        textController?.parseUpdates(newValue: stringValue)
        updateStringValue(textController!.rowString())
    }

    func control(_: NSControl, textShouldBeginEditing _: NSText) -> Bool {
        print("ARGUMENT: \(#function)")
        return true
    }

    func control(_: NSControl, textShouldEndEditing _: NSText) -> Bool {
        print("ARGUMENT: \(#function)")
        return true
    }

    func textView(_: NSTextView, willChangeSelectionFromCharacterRange oldSelectedCharRange: NSRange, toCharacterRange newSelectedCharRange: NSRange) -> NSRange {
        if oldSelectedCharRange.length == 0, newSelectedCharRange.length == 0, !isEditing {
            let extent = textController!.getExtentForIdx(idx: oldSelectedCharRange.lowerBound)
            return NSRange(location: extent.start, length: extent.end - extent.start)
        }

        return newSelectedCharRange
    }

    func textView(_: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        print(#function)
        print(commandSelector)
        if commandSelector == #selector(insertTab) {
            if self.currentArgumentIndex + 1 < self.column!.arguments.count {
                self.selectArgument(idx: self.currentArgumentIndex + 1)
                return true
            } else {
                self.resignFirstResponder()
                return true
            }
        } else if commandSelector == #selector(insertBacktab) {
            if self.currentArgumentIndex - 1 >= 0 {
                self.selectArgument(idx: self.currentArgumentIndex - 1)
                return true
            } else {
                self.resignFirstResponder()
                return true
            }
        }
//            if self.currentArgumentIndex + 1 < self.column!.arguments.count {
//                self.selectArgument(idx: self.currentArgumentIndex + 1)
//                return true
//            } else {
//                let ip = self.parentView!.parentView!.sheetModel.findCellIndexPath(cell_to_find: self.parentView!.cell)
//                if ip != nil {
//                    (self.parentView!.parentView!.delegate as! Coordinator).focusNextCell(ip!)
//                }
//                self.resignFirstResponder()
//                return true
//            }
//        } else if commandSelector == #selector(insertBacktab) {
//            if self.currentArgumentIndex - 1 >= 0 {
//                self.selectArgument(idx: self.currentArgumentIndex - 1)
//                return true
//            } else {
//                self.parentView!.focusOffset()
//                self.resignFirstResponder()
//                return true
//            }
//        } else if commandSelector == #selector(moveDown) {
//            let ip = self.parentView!.parentView!.sheetModel.findVisibleCellIndexPath(cell_to_find: self.parentView!.cell)
//            if ip != nil {
//                (self.parentView!.parentView!.delegate as! Coordinator).focusNextCell(ip!)
//                (self.parentView!.parentView!.delegate as! Coordinator).focusField(IndexPath(item: self.currentArgumentIndex, section: 0))
//            }
//            let _ = self.resignFirstResponder()
//            return true
//        } else if commandSelector == #selector(moveUp) {
//            var ip = self.parentView!.parentView!.sheetModel.findVisibleCellIndexPath(cell_to_find: self.parentView!.cell)
//
//            if ip != nil {
//                ip!.item = ip!.item - 1
//                if ip!.item < 0 {
//                    return true
//                }
//                (self.parentView!.parentView!.delegate as! Coordinator).focusCell(ip!)
//                (self.parentView!.parentView!.delegate as! Coordinator).focusField(IndexPath(item: self.currentArgumentIndex, section: 0))
//                return true
//            }
//            let _ = self.resignFirstResponder()
//        } else if commandSelector == #selector(moveRight) {
//            var ip = self.parentView!.parentView!.sheetModel.findCellInNextColumnIndexPath(cell: self.parentView!.cell)
//
//            if ip != nil {
//                (self.parentView!.parentView!.delegate as! Coordinator).focusNextCell(ip!)
//                (self.parentView!.parentView!.delegate as! Coordinator).focusField(IndexPath(item: self.currentArgumentIndex, section: 0))
//                return true
//            }
//            let _ = self.resignFirstResponder()
//        } else if commandSelector == #selector(moveLeft) {
//            var ip = self.parentView!.parentView!.sheetModel.findCellInPrevColumnIndexPath(cell: self.parentView!.cell)
//
//            if ip != nil {
//                (self.parentView!.parentView!.delegate as! Coordinator).focusNextCell(ip!)
//                (self.parentView!.parentView!.delegate as! Coordinator).focusField(IndexPath(item: self.currentArgumentIndex, section: 0))
//                return true
//            }
//            let _ = self.resignFirstResponder()
//        }

        return false
    }
}
