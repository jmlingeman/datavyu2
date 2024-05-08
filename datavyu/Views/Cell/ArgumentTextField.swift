//
//  ArgumentTextField.swift
//  datavyu
//
//  Created by Jesse Lingeman on 2/9/24.
//

import Foundation
import AppKit

class ArgumentTextField: NSTextField {
    var argument: Argument?
    var parentView: CellViewUIKit?
    var argumentView: ArgumentViewUIKit?
    
    var lastIntrinsicSize = NSSize.zero
    var hasLastIntrinsicSize = false
    
    func configure(argument: Argument) {
        self.argument = argument
        self.delegate = self
    }
    
    func configureParentView(parentView: CellViewUIKit) {
        self.parentView = parentView
    }
    
    override func becomeFirstResponder() -> Bool {
        guard super.becomeFirstResponder() else {
            return false
        }
        if let editor = self.currentEditor() {
            editor.perform(#selector(selectAll(_:)), with: self, afterDelay: 0)
        }
        if parentView != nil {
            parentView!.setSelected()
            parentView?.parentView?.lastEditedArgument = argument
        }
                        
        return true
    }
    
    override var intrinsicContentSize: NSSize {
        get {
            var intrinsicSize = lastIntrinsicSize
            
            if self.argumentView != nil && self.argumentView!.argSelected || !hasLastIntrinsicSize {
                
                intrinsicSize = super.intrinsicContentSize
                
                // If we’re being edited, get the shared NSTextView field editor, so we can get more info
                if let textView = self.window?.fieldEditor(false, for: self) as? NSTextView, let textContainer = textView.textContainer, var usedRect = textView.textContainer?.layoutManager?.usedRect(for: textContainer) {
                    usedRect.size.height += 5.0 // magic number! (the field editor TextView is offset within the NSTextField. It’s easy to get the space above (it’s origin), but it’s difficult to get the default spacing for the bottom, as we may be changing the height
                    intrinsicSize.height = usedRect.size.height
                }
                
                lastIntrinsicSize = intrinsicSize
                hasLastIntrinsicSize = true
            }
            
            return intrinsicSize
        }
    }
    
}

extension ArgumentTextField: NSTextFieldDelegate, NSTextViewDelegate {
    
    func textField(_ textField: NSTextField, textView: NSTextView, candidatesForSelectedRange selectedRange: NSRange) -> [Any]? {
        print("ARGUMENT: \(#function)")
        return nil
    }
    
    func textField(_ textField: NSTextField, textView: NSTextView, candidates: [NSTextCheckingResult], forSelectedRange selectedRange: NSRange) -> [NSTextCheckingResult] {
        print("ARGUMENT: \(#function)")
        return candidates
    }
    
    func textField(_ textField: NSTextField, textView: NSTextView, shouldSelectCandidateAt index: Int) -> Bool {
        print("ARGUMENT: \(#function)")
        return true
    }
    
    func controlTextDidBeginEditing(_ obj: Notification) {
        print("ARGUMENT: \(#function)")
        self.argumentView?.argSelected = true
        self.parentView!.lastEditedField = LastEditedField.arguments
        self.parentView?.parentView?.lastEditedArgument = self.argument
    }
    
    func controlTextDidEndEditing(_ obj: Notification) {
        print("ARGUMENT: \(#function)")
        self.parentView!.lastEditedField = LastEditedField.arguments
        self.parentView?.parentView?.lastEditedArgument = self.argument
        if let textField = obj.object as? NSTextField {
            if textField.stringValue != argument!.value {
                argument!.setValue(value: textField.stringValue)
            }
        }
        self.argumentView?.argSelected = false
    }
        
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        print("ARGUMENT: \(#function)")
        print(commandSelector)
        
        return true
    }
    
    func controlTextDidChange(_ obj: Notification) {
        print(self)
        print("ARGUMENT: \(#function)")
        self.parentView!.lastEditedField = LastEditedField.arguments
        self.parentView?.parentView?.lastEditedArgument = self.argument
        self.invalidateIntrinsicContentSize()
    }
    
    func control(_ control: NSControl, textShouldBeginEditing fieldEditor: NSText) -> Bool {
        print("ARGUMENT: \(#function)")
        return true
    }
    
    func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
        print("ARGUMENT: \(#function)")
        return true
    }
    
    func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        print(#function)
        if commandSelector == #selector(insertTab) {
            
            print("TABBING OUT OF ARGUMENT")
            self.parentView!.lastEditedField = LastEditedField.arguments
            self.parentView!.parentView!.lastEditedArgument = self.argument
            if argument != nil && parentView?.cell.arguments.last == argument {
                print("Trying to select next cell")
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
