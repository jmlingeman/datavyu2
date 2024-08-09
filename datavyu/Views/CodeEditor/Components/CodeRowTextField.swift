
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
        Logger.info("formatting", partialString)

        // Ability to reset your field (otherwise you can't delete the content)
        // You can check if the field is empty later
        if partialString.isEmpty {
            return true
        }

        let sepCount = partialString.filter { c in
            String(c) == CellTextController.argumentSeperator
        }.count

        if sepCount != column!.arguments.count - 1 {
            Logger.info("INVALID")
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

struct CodeRowTextFieldView: NSViewRepresentable {
    @ObservedObject var column: ColumnModel
    @ObservedObject var selectedArgument: SelectedArgument
    typealias NSViewType = NSTextField
    @State var nsView: CodeRowTextField = .init()

    init(column: ColumnModel, selectedArgument: SelectedArgument) {
        self.column = column
        self.selectedArgument = selectedArgument
        nsView.configure(column: column, selectedArgument: selectedArgument)
    }

    func makeNSView(context _: Context) -> NSTextField {
        nsView.configure(column: column, selectedArgument: selectedArgument)
        return nsView
    }

    func updateNSView(_: NSTextField, context _: Context) {
        // Note this line:
        nsView.column = column
        nsView.updateStringValue(nsView.textController!.rowString())

        nsView.invalidateIntrinsicContentSize()
        Logger.info(nsView.fittingSize)
//        Logger.info(nsView.sizeToFit())
        nsView.setNeedsDisplay(nsView.bounds)
    }

    func selectArgument(idx: Int) {
        nsView.updateStringValue()
        nsView.selectArgument(idx: idx)
    }
}

class CodeRowTextField: NSTextField {
    var column: ColumnModel?
    var selectedArgument: SelectedArgument?

    var isEditing: Bool = false
    var isUpdating: Bool = false

    var lastIntrinsicSize = NSSize.zero
    var hasLastIntrinsicSize = false

    var textController: CodeEditorRowTextController?

    var keyEventHandler: Any?

    func configure(column: ColumnModel, selectedArgument: SelectedArgument) {
        self.column = column
        self.selectedArgument = selectedArgument
        delegate = self
        textController = CodeEditorRowTextController(column: column)
        updateStringValue(textController!.rowString())

        formatter = CodeRowTextFormatter()
        (formatter as! CodeRowTextFormatter).configure(textController: textController!, column: column)
    }

    func updateStringValue() {
        if textController != nil {
            let columnString = textController!.parseUpdates(newValue: textController!.rowString())
            stringValue = columnString
            invalidateIntrinsicContentSize()
        }
    }

    func updateStringValue(_ s: String) {
        let columnString = textController!.parseUpdates(newValue: s)
        stringValue = columnString
        invalidateIntrinsicContentSize()
    }

    func selectColumnName() {
        let extents = textController!.columnNameExtent
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if self.currentEditor() != nil {
                self.currentEditor()?.selectedRange = NSRange(location: extents.start, length: extents.end - extents.start)
                self.selectedArgument!.argumentIdx! = -1
            }
        }
    }

    func selectArgument(idx: Int) {
        Logger.info(#function)
        if textController != nil {
            let extents = textController!.getExtentOfArgument(idx: idx)
            Logger.info("Selecting \(idx)")
            isUpdating = true
            if extents != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                    if self.currentEditor() != nil {
                        self.currentEditor()?.selectedRange = NSRange(location: extents!.start, length: extents!.end - extents!.start)
                        self.selectedArgument?.argumentIdx = idx
                        self.selectedArgument?.column = self.column
                    }
                    self.isUpdating = false
                }
            }
        }
    }

    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        isEditing = false
    }

    override func becomeFirstResponder() -> Bool {
//        guard super.becomeFirstResponder() else {
//            return false
//        }

//        selectColumnName()

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

extension CodeRowTextField: NSTextFieldDelegate, NSTextViewDelegate {
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
        textController?.parseUpdates(newValue: stringValue)
        updateStringValue(textController!.rowString())
    }

    func control(_: NSControl, textView _: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        Logger.info("ARGUMENT: \(#function)")
        Logger.info(commandSelector)

        return true
    }

    func controlTextDidChange(_: Notification) {
        Logger.info(self)
        Logger.info("ARGUMENT: \(#function)")
        isEditing = true
        textController?.parseUpdates(newValue: stringValue)
        updateStringValue(textController!.rowString())
    }

    func control(_: NSControl, textShouldBeginEditing _: NSText) -> Bool {
        Logger.info(#function)
        Logger.info("ARGUMENT: \(#function)")
        return true
    }

    func control(_: NSControl, textShouldEndEditing _: NSText) -> Bool {
        Logger.info(#function)
        Logger.info("ARGUMENT: \(#function)")
        return true
    }

//    func textViewDidChangeSelection(_ notification: Notification) {
//        Logger.info(#function)
//        Logger.info("SELECT CHANGED")
//        Logger.info(notification.description)
//        let range = self.currentEditor()?.selectedRange
//        if range != nil {
//            let argIdx = self.textController?.getArgIdxForIdx(idx: range!.location)
//            selectedArgument?.argumentIdx = argIdx
//        }
//    }

    override var intrinsicContentSize: NSSize {
        if cell!.wraps {
            let fictionalBounds = NSRect(x: bounds.minX, y: bounds.minY, width: bounds.width, height: CGFloat.greatestFiniteMagnitude)
            return cell!.cellSize(forBounds: fictionalBounds)
        } else {
            return super.intrinsicContentSize
        }
    }

    func textView(_: NSTextView, willChangeSelectionFromCharacterRange oldSelectedCharRange: NSRange, toCharacterRange newSelectedCharRange: NSRange) -> NSRange {
        Logger.info(#function)
        if abs(newSelectedCharRange.location - oldSelectedCharRange.location) > 2 {
            isEditing = false
        }
        if newSelectedCharRange.location != 0, !isEditing, !isUpdating {
//            let extent = textController!.getExtentForIdx(idx: oldSelectedCharRange.lowerBound)
            let argIdx = textController!.getArgIdxForIdx(idx: newSelectedCharRange.lowerBound)

            // Update the latest selected argument
            DispatchQueue.main.async {
                self.selectedArgument?.column = self.column
                self.selectedArgument?.argumentIdx = argIdx
            }
            let extent = textController!.getExtentOfArgument(idx: argIdx)

            if extent == nil {
                return newSelectedCharRange
            }

            Logger.info(selectedArgument?.argumentIdx)

            // Allow user to click into the text

            if oldSelectedCharRange.location >= extent!.start, oldSelectedCharRange.location <= extent!.end, newSelectedCharRange.location >= extent!.start, newSelectedCharRange.location <= extent!.end {
                return newSelectedCharRange
            }
            return NSRange(location: extent!.start, length: extent!.end - extent!.start)
        }

        return newSelectedCharRange
    }

    func textView(_: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        Logger.info(#function)
        Logger.info(commandSelector)
        if commandSelector == #selector(insertTab) {
            if self.selectedArgument!.argumentIdx! + 1 < self.column!.arguments.count {
                self.selectArgument(idx: self.selectedArgument!.argumentIdx! + 1)
                return true
            } else {
                self.resignFirstResponder()
                return true
            }
        } else if commandSelector == #selector(insertBacktab) {
            if self.selectedArgument!.argumentIdx! - 1 >= 0 {
                self.selectArgument(idx: self.selectedArgument!.argumentIdx! - 1)
                return true
            } else if self.selectedArgument!.argumentIdx! - 1 < 0 {
                self.selectColumnName()
                return true
            } else {
                self.resignFirstResponder()
                return true
            }
        }
        return false
    }
}
