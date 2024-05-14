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
