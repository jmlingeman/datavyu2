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
        }
        
        return true
    }
}

extension ArgumentTextField: NSTextFieldDelegate, NSTextViewDelegate {
    
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
            //            argument!.setValue(value: textField.stringValue)
        }
    }
        
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        print(#function)
        print(commandSelector)
        
        return true
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
    
    func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        print(#function)
        if commandSelector == #selector(insertTab) {
            print("TABBING OUT OF ARGUMENT")
            /* TODO: Have this call the collectionview to have it switch focus to the next cell
             using makeFirstResponder */
            if argument != nil && argument!.isLastArgument {
                (self.parentView!.parentView!.delegate as! Coordinator).focusNextCell()
                return true
            }
            
        }

        return false
    }
    
    
}
