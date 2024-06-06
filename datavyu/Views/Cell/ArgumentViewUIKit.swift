//
//  ArgumentViewUIKit.swift
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
        argument = dummyArg
        argumentLabel = NSTextField()
        argumentValue = ArgumentTextField()

        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    func configureCell(with argument: Argument) {
        self.argument = argument
        argumentLabel.stringValue = argument.name
        argumentValue.stringValue = argument.value
        print("Configuring Arg: \(argument.name) \(argument.value)")
        argumentValue.configure(argument: argument)

        if argument.column!.isFinished {
            argumentValue.isEnabled = false
        } else {
            argumentValue.isEnabled = true
        }
    }

    override func prepareForReuse() {
        // Attach it to a dummy cell until that gets replaced
        argument = dummyArg
        argumentLabel.stringValue = ""
        argumentValue.stringValue = ""
        argumentValue.isEnabled = true
    }

    func configureParentView(with parentView: CellViewUIKit) {
        self.parentView = parentView
        argumentValue.configureParentView(parentView: parentView)
        argumentValue.argumentView = self
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        configureCell(with: argument)
    }

    override func viewDidAppear() {}

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
