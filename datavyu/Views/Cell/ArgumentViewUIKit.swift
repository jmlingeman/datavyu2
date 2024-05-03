//
//  ArgumentView.swift
//  datavyu
//
//  Created by Jesse Lingeman on 1/30/24.
//

import Cocoa
import SwiftUI

class ArgumentViewUIKit: NSCollectionViewItem {
    static let identifier: String = "ArgumentViewUIKit"
    
    @IBOutlet var argumentLabel: NSTextField!
    @IBOutlet var argumentValue: ArgumentTextField!
    
    @ObservedObject var argument: Argument
    var parentView: CellViewUIKit?
    var argSelected: Bool = false
    
    override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?) {
        self.argument = Argument()
        self.argumentLabel = NSTextField()
        self.argumentValue = ArgumentTextField()

        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    func configureCell(with argument: Argument) {
        
        self.argument = argument
        self.argumentLabel.stringValue = argument.name
        self.argumentValue.stringValue = argument.value
        self.argumentValue.configure(argument: argument)
//        (self.argumentValue.delegate as! ArgumentCoordinator).configure(argument: argument, view: self)
    }
    
    func configureParentView(with parentView: CellViewUIKit) {
        self.parentView = parentView
        self.argumentValue.configureParentView(parentView: parentView)
        self.argumentValue.argumentView = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        self.configureCell(with: self.argument)
    }
    
    override func viewDidAppear() {

    }
    
    override func keyDown(with event: NSEvent) {
        print("From Arg Cell View: \(event.keyCode)")
    }
    
    
    
}

@objc class ArgumentCoordinator: NSObject {
    var argument: Argument?
    var view: ArgumentViewUIKit?
    
    override init() {
        super.init()
    }
    
    init(argument: Argument) {
        self.argument = argument
    }
    
    func configure(argument: Argument, view: ArgumentViewUIKit) {
        self.argument = argument
        self.view = view
    }
}

extension ArgumentCoordinator: NSTextFieldDelegate {
    
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
        self.view?.argSelected = true
    }
    
    func controlTextDidEndEditing(_ obj: Notification) {
        print(#function)
        if let textField = obj.object as? NSTextField {
//            self.view?.parentView?.focusObject = textField
            self.view?.argSelected = false
//            argument!.setValue(value: textField.stringValue)
        }
    }
    
    func controlTextDidChange(_ obj: Notification) {
        print(self)
        print(#function)
        self.view?.argumentValue.invalidateIntrinsicContentSize()
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
