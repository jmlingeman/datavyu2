//
//  EditableLabel.swift
//  datavyu
//
//  Created by Jesse Lingeman on 6/4/23.
//

import SwiftUI
import AppKit
import Combine

public struct EditableLabel: View {
    @Binding var text: String
    
    @State var editProcessGoing = false
    @FocusState var isFocused
    @State private var textSelected = false
    @State private var renameTmpText: String = ""
    
    let onEditEnd: () -> Void
    
    public init(_ txt: Binding<String>, onEditEnd: @escaping () -> Void = {}) {
        _text = txt
        self.onEditEnd = onEditEnd
    }
    
    @ViewBuilder
    public var body: some View {
        ZStack {
            // Text variation of View
            if(!editProcessGoing) {
                Text(text)
            } else {
                
                // TextField for edit mode of View
                TextField("", text: $text)
                    .onSubmit {
                        editProcessGoing = false; onEditEnd()
                    }
                    .onAppear {
                        renameTmpText = ""
                        isFocused = true
                    }
                    .focused($isFocused)
                    .onReceive(NotificationCenter.default.publisher(for: NSTextView.didChangeSelectionNotification)) { obj in
                        if let textView = obj.object as? NSTextView {
                            guard !textSelected else { return }
                            let range = NSRange(location: 0, length:     textView.string.count)
                            textView.setSelectedRange(range)
                            textSelected = true
                        }
                    }
            }
        }

        // Enable EditMode on double tap
        .onTapGesture(count: 2, perform: { editProcessGoing = true; print(editProcessGoing) } )
        // Exit from EditMode on Esc key press
        .onExitCommand(perform: { editProcessGoing = false })
    }
}

struct EditableLabel_Previews: PreviewProvider {
    static var previews: some View {
        @State var name: String = "test"
        EditableLabel($name, onEditEnd: {print(name)})
    }
}
