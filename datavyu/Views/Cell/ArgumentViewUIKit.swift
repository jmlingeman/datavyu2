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
    
    let dummyArg = Argument()
    
    override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?) {
        self.argument = dummyArg
        self.argumentLabel = NSTextField()
        self.argumentValue = ArgumentTextField()

        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    func configureCell(with argument: Argument) {
        
        self.argument = argument
        self.argumentLabel.stringValue = argument.name
        self.argumentValue.stringValue = argument.value
        print("Configuring Arg: \(argument.name) \(argument.value)")
        self.argumentValue.configure(argument: argument)
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
