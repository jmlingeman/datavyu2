//
//  ArgumentTextField.swift
//  datavyu
//
//  Created by Jesse Lingeman on 2/9/24.
//

import AppKit
import Foundation

class ArgumentTextField: NSTextField {
    var argument: Argument?
    var parentView: CellViewUIKit?
    var argumentView: ArgumentViewUIKit?

    var lastIntrinsicSize = NSSize.zero
    var hasLastIntrinsicSize = false

    func configure(argument: Argument) {
        self.argument = argument
        delegate = self
        cell?.wraps = false
        autoresizingMask = [.height, .width]
    }

    func configureParentView(parentView: CellViewUIKit) {
        self.parentView = parentView
    }

    override func becomeFirstResponder() -> Bool {
        guard super.becomeFirstResponder() else {
            return false
        }
        if let editor = currentEditor() {
            editor.perform(#selector(selectAll(_:)), with: self, afterDelay: 0)
        }
        if parentView != nil {
            parentView!.setSelected()
            parentView?.parentView?.lastEditedArgument = argument
        }

        return true
    }

//    override var intrinsicContentSize: NSSize {
//        var intrinsicSize = lastIntrinsicSize
//
//        Logger.info("Trying to set new size")
//        if argumentView != nil && argumentView!.argSelected {
//            intrinsicSize = super.intrinsicContentSize
//
//            // If we’re being edited, get the shared NSTextView field editor, so we can get more info
//            if let textView = window?.fieldEditor(false, for: self) as? NSTextView, let textContainer = textView.textContainer, var usedRect = textView.textContainer?.layoutManager?.usedRect(for: textContainer) {
//                usedRect.size.height += 5.0 // magic number! (the field editor TextView is offset within the NSTextField. It’s easy to get the space above (it’s origin), but it’s difficult to get the default spacing for the bottom, as we may be changing the height
//                intrinsicSize.height = usedRect.size.height
//            }
//
//            lastIntrinsicSize = intrinsicSize
//            Logger.info(lastIntrinsicSize)
//            hasLastIntrinsicSize = true
//            frame = CGRect(origin: frame.origin, size: intrinsicSize)
//        }
//
//        return intrinsicSize
//    }

    override var intrinsicContentSize: NSSize {
        // Guard the cell exists and wraps
        Logger.info("setting intrin")

        guard let cell = cell else { return super.intrinsicContentSize }

        // Use intrinsic width to jive with autolayout
        let width = super.intrinsicContentSize.width

        // Set the frame height to a reasonable number
        frame.size.height = 750.0

        // Calcuate height
        let height = cell.cellSize(forBounds: frame).height

        return NSMakeSize(width, height)
    }

    override func textDidChange(_ notification: Notification) {
        super.textDidChange(notification)
        Logger.info("invalidate intrin")
        super.invalidateIntrinsicContentSize()
    }
}

extension ArgumentTextField: NSTextFieldDelegate, NSTextViewDelegate {
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
        argumentView?.argSelected = true
        parentView!.lastEditedField = LastEditedField.arguments
        parentView?.parentView?.lastEditedArgument = argument
    }

    func controlTextDidEndEditing(_ obj: Notification) {
        Logger.info("ARGUMENT: \(#function)")
        parentView!.lastEditedField = LastEditedField.arguments
        parentView?.parentView?.lastEditedArgument = argument
        if let textField = obj.object as? NSTextField {
            if textField.stringValue != argument!.value {
                argument!.setValue(value: textField.stringValue)
            }
        }
        argumentView?.argSelected = false
    }

    func control(_: NSControl, textView _: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        Logger.info("ARGUMENT: \(#function)")
        Logger.info(commandSelector)

        return true
    }

    func controlTextDidChange(_: Notification) {
        Logger.info("ARGUMENT: \(#function)")
        parentView!.lastEditedField = LastEditedField.arguments
        parentView?.parentView?.lastEditedArgument = argument
        invalidateIntrinsicContentSize()
    }

    func control(_: NSControl, textShouldBeginEditing _: NSText) -> Bool {
        Logger.info("ARGUMENT: \(#function)")
        return true
    }

    func control(_: NSControl, textShouldEndEditing _: NSText) -> Bool {
        Logger.info("ARGUMENT: \(#function)")
        return true
    }

    func textView(_: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        Logger.info(#function)
        if commandSelector == #selector(insertTab) {
            Logger.info("TABBING OUT OF ARGUMENT")
            self.parentView!.lastEditedField = LastEditedField.arguments
            self.parentView!.parentView!.lastEditedArgument = self.argument
            if argument != nil, parentView?.cell.arguments.last == argument {
                Logger.info("Trying to select next cell")
                let ip = self.parentView!.parentView!.sheetModel.findCellIndexPath(cell_to_find: self.parentView!.cell)
                if ip != nil {
                    (self.parentView!.parentView!.delegate as! Coordinator).focusNextCell(ip!)
                }
//                self.resignFirstResponder()
                return true
            }
//            else if argument != nil && parentView?.cell.arguments.last != argument {
//                self.parentView!.focusNextArgument(argument!)
//                self.resignFirstResponder()
//                return true
//            }
        }

        return false
    }
}
