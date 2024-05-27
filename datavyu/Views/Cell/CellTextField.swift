
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
    
    override func getObjectValue(_ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?, for string: String, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        obj?.pointee = string as NSString
        return true
    }
    
    override func isPartialStringValid(_ partialString: String, newEditingString newString: AutoreleasingUnsafeMutablePointer<NSString?>?, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        
        print("formatting", partialString)
        
        // Ability to reset your field (otherwise you can't delete the content)
        // You can check if the field is empty later
        if partialString.isEmpty {
            return true
        }
        
        let sepCount = partialString.filter({ c in
            return String(c) == CellTextController.argumentSeperator
        }).count
        
        if sepCount != cell!.arguments.count - 1 {
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
        self.delegate = self
        self.cellTextController = CellTextController(cell: cellModel)
        self.updateStringValue(cellTextController!.argumentString())
        (self.formatter as! CellTextFormatter).configure(cellTextController: self.cellTextController!, cell: self.cellModel!)
    }
    
    func updateStringValue(_ s: String) {
        DispatchQueue.main.async {
            self.stringValue = s
        }
    }
    
    func configureParentView(parentView: CellViewUIKit) {
        self.parentView = parentView
    }
    
    func selectArgument(idx: Int) {
        let extents = cellTextController!.getExtentOfArgument(idx: idx)
        self.currentEditor()!.selectedRange = NSRange(location: extents.start, length: extents.end - extents.start)
        self.currentArgumentIndex = idx
    }
    
//    override func mouseDown(with event: NSEvent) {
//        self.sele
//    }
    
    
    
    override func becomeFirstResponder() -> Bool {
        guard super.becomeFirstResponder() else {
            return false
        }
        
        if parentView != nil {
            parentView!.setSelected()
//            parentView?.parentView?.lastEditedArgument = argument
        }
        
        DispatchQueue.main.async {
            self.selectArgument(idx: 0)
        }
        
        keyEventHandler = NSEvent.addLocalMonitorForEvents(matching: NSEvent.EventTypeMask.keyDown) { event in
            let s = event.characters
            if s!.contains(",") {
                print("Intercepted comma")
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

extension CellTextField: NSTextFieldDelegate, NSTextViewDelegate {
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
        self.isEditing = true
//        parentView!.lastEditedField = LastEditedField.arguments
    }
    
    func controlTextDidEndEditing(_ obj: Notification) {
        print("ARGUMENT: \(#function)")
        self.isEditing = false
//        parentView!.lastEditedField = LastEditedField.arguments
//        if let textField = obj.object as? NSTextField {
//            if textField.stringValue != argument!.value {
//                argument!.setValue(value: textField.stringValue)
//            }
//        }
        cellTextController?.parseUpdates(newValue: self.stringValue)
        self.updateStringValue(cellTextController!.argumentString())
    }
    
    func control(_: NSControl, textView _: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        print("ARGUMENT: \(#function)")
        print(commandSelector)
        
        return true
    }
    
    func controlTextDidChange(_: Notification) {
        print(self)
        print("ARGUMENT: \(#function)")
//        parentView!.lastEditedField = LastEditedField.arguments
        cellTextController?.parseUpdates(newValue: self.stringValue)
        self.updateStringValue(cellTextController!.argumentString())
//        invalidateIntrinsicContentSize()
    }
    
    func control(_: NSControl, textShouldBeginEditing _: NSText) -> Bool {
        print("ARGUMENT: \(#function)")
        return true
    }
    
    func control(_: NSControl, textShouldEndEditing _: NSText) -> Bool {
        print("ARGUMENT: \(#function)")
        return true
    }
    
    func textView(_ textView: NSTextView, willChangeSelectionFromCharacterRange oldSelectedCharRange: NSRange, toCharacterRange newSelectedCharRange: NSRange) -> NSRange {
        if oldSelectedCharRange.length == 0 && newSelectedCharRange.length == 0 && !isEditing {
            let extent = cellTextController!.getExtentForIdx(idx: oldSelectedCharRange.lowerBound)
            return NSRange(location: extent.start, length: extent.end - extent.start)
        }
        
        return newSelectedCharRange
    }
    
    func textView(_: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        print(#function)
        if commandSelector == #selector(insertTab) {
            print("TABBING OUT OF ARGUMENT")
            if self.currentArgumentIndex + 1 < self.cellModel!.arguments.count {
                self.selectArgument(idx: self.currentArgumentIndex + 1)
                return true
            }
//            self.parentView!.lastEditedField = LastEditedField.arguments
            
//            if argument != nil, parentView?.cell.arguments.last == argument {
//                print("Trying to select next cell")
//                let ip = self.parentView!.parentView!.sheetModel.findCellIndexPath(cell_to_find: self.parentView!.cell)
//                if ip != nil {
//                    (self.parentView!.parentView!.delegate as! Coordinator).focusNextCell(ip!)
//                }
//                //                self.resignFirstResponder()
//                return true
//            }
            //            else if argument != nil && parentView?.cell.arguments.last != argument {
            //                self.parentView!.focusNextArgument(argument!)
            //                self.resignFirstResponder()
            //                return true
            //            }
        }
        
        return false
    }
}