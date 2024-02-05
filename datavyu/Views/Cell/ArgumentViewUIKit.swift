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
    @IBOutlet var argumentValue: NSTextField!
    
    @ObservedObject var argument: Argument
    
    override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?) {
        self.argument = Argument()
        self.argumentLabel = NSTextField()
        self.argumentValue = NSTextField()

        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    func configureCell(with argument: Argument) {
        
        self.argument = argument
        self.argumentLabel.stringValue = argument.name
        self.argumentValue.stringValue = argument.value
        (self.argumentValue.delegate as! ArgumentCoordinator).configure(argument: argument)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        self.configureCell(with: self.argument)
    }
    
    
    
}

@objc class ArgumentCoordinator: NSObject {
    var argument: Argument?
    
    override init() {
        super.init()
    }
    
    init(argument: Argument) {
        self.argument = argument
    }
    
    func configure(argument: Argument) {
        self.argument = argument
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
    }
    
    func controlTextDidEndEditing(_ obj: Notification) {
        print(#function)
        if let textField = obj.object as? NSTextField {
            print("Setting value")
            argument!.setValue(value: textField.stringValue)
        }
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
}
