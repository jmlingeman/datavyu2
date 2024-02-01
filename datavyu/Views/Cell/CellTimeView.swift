import SwiftUI
import AppKit

class CellTimeTextField: NSTextField {
    private var hostingView: NSHostingView<CellTimeView>?
    
    static let identifier: String = "CellTimeTextField"
    
    public func configure(_ article: Binding<Int>) {
        for v in self.subviews {
            v.removeFromSuperview()
        }
        let rootView = CellTimeView(time: article)
        let contentView = NSHostingView(rootView: rootView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(contentView)
        
        contentView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        contentView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        contentView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        contentView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
    }
}

struct CellTimeView: NSViewRepresentable {
    typealias NSViewType = NSTextField
    
    var time: Binding<Int>
    
    var onEditingChanged: ((Bool) -> ())? = nil
    var onEditingCommit: (() -> ())? = nil
    
    func makeNSView(context: Context) -> NSTextField {
        let view = NSTextField()
        
        print("MAKING NS VIEW WITH COORDINATOR \(context.coordinator)")
        view.delegate = context.coordinator
        view.font = NSFont.preferredFont(forTextStyle: .body)
//        view.textColor = NSColor.label
        
        return view
    }
    
    func updateNSView(_ nsView: NSTextField, context: Context) {
        print("UPDATING TEXT FIELD")
        nsView.stringValue = formatTimestamp(timestamp: self.time.wrappedValue)
//        nsView.font = NSFont.preferredFont(forTextStyle: .body, compatibleWith: traits)
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: CellTimeView
        
        init(_ parent: CellTimeView) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: NSTextField) {
            print("EDIteD")
//            self.parent.time = timestringToTimestamp(timestring: textView.stringValue)
        }
        
        func textViewDidBeginEditing(_ textView: NSTextField) {
            print("EDITING")
            parent.onEditingChanged?(true)
        }
        
        func textViewDidEndEditing(_ textView: NSTextField) {
            print("DONE")
            parent.onEditingCommit?()
            parent.onEditingChanged?(false)
        }
        
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
        }
        
        func controlTextDidChange(_ obj: Notification) {
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
    }
}
