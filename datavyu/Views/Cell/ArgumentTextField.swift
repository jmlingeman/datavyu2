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
            (self.parentView!.parentView!.delegate as! Coordinator).focusedField = self
            parentView!.setSelected()
        }
                        
        return true
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
    }
    
    func controlTextDidEndEditing(_ obj: Notification) {
        print("ARGUMENT: \(#function)")
        self.parentView?.focusObject = self
        self.parentView!.lastEditedField = LastEditedField.arguments
        if let textField = obj.object as? NSTextField {
            if textField.stringValue != argument!.value {
                print("SETTING FOCUS OB")
                self.parentView?.focusObject = self
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
            if argument != nil && argument!.isLastArgument {
                print("Trying to select next cell")
                let ip = self.parentView!.parentView!.sheetModel.findCellIndexPath(cell_to_find: self.parentView!.cell)
                if ip != nil {
                    (self.parentView!.parentView!.delegate as! Coordinator).focusNextCell(ip!)
                }
//                self.resignFirstResponder()
                return true
            } 
//            else if argument != nil && !argument!.isLastArgument {
//                (self.parentView! as! CellViewUIKit).focusNextArgument()
//                self.resignFirstResponder()
//                return true
//            }
            
        }

        return false
    }
    
    
}
