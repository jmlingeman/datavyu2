//
//  ArgumentView.swift
//  datavyu
//
//  Created by Jesse Lingeman on 1/30/24.
//

import Cocoa

class ArgumentView: NSCollectionViewItem {
    static let identifier: String = "ArgumentView"
    
    @IBOutlet var argumentLabel: NSTextField!
    @IBOutlet var argumentValue: NSTextField!
    
    var argument: Argument
    
    init(argument: Argument) {
        self.argumentLabel = NSTextField(string: argument.name)
        self.argumentValue = NSTextField(string: argument.value)
        self.argument = argument
        
        super.init(nibName: "ArgumentView", bundle: nil)
    }
    
    func configureCell(with argument: Argument) {
        self.argumentLabel.stringValue = argument.name
        self.argumentValue.stringValue = argument.value
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    
    
}
