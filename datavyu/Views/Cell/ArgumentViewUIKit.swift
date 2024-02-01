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
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    
    
}
